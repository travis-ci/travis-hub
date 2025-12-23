require 'travis/addons/serializer/formats'

module Travis
  module Addons
    module Serializer
      module Tasks
        # Serializer for MS Teams Adaptive Cards
        # JSON payload according to MS Teams webhook format
        # https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using
        class Msteams
          include Formats

          attr_reader :build, :repository, :request, :commit, :pull_request, :tag

          def initialize(build)
            @build = build
            @repository = build.repository
            @request = build.request
            @commit = build.commit
            @pull_request = build.pull_request
            @tag = build.tag
          end

          # Returns MS Teams webhook payload with Adaptive Card
          def data
            {
              type: 'message',
              attachments: [
                {
                  contentType: 'application/vnd.microsoft.card.adaptive',
                  contentUrl: nil,
                  content: adaptive_card
                }
              ]
            }
          end

          private

          # Main Adaptive Card structure
          def adaptive_card
            {
              type: 'AdaptiveCard',
              '$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
              version: '1.2',
              body: simple_card_body
            }
          end

          def simple_card_body
            [
              simple_header,
              simple_metadata,
              commit_message_block,
              simple_actions
            ].compact
          end

          def simple_header
            {
              type: 'ColumnSet',
              columns: [
                {
                  type: 'Column',
                  width: 'auto',
                  items: [{
                    type: 'TextBlock',
                    text: status_emoji,
                    size: 'ExtraLarge'
                  }]
                },
                {
                  type: 'Column',
                  width: 'stretch',
                  items: [{
                    type: 'TextBlock',
                    text: "**#{repository.slug}**",
                    size: 'Large',
                    weight: 'Bolder'
                  }],
                  verticalContentAlignment: 'Center'
                }
              ]
            }
          end

          def simple_metadata
            {
              type: 'FactSet',
              facts: [
                { title: 'Status', value: status_text },
                { title: 'Branch', value: build.branch || 'unknown' },
                { title: 'Commit', value: commit.commit[0..6] },
                { title: 'Author', value: commit.author_name || 'unknown' },
                { title: 'Duration', value: format_duration }
              ]
            }
          end

          def format_duration
            return 'N/A' unless build.duration

            minutes = build.duration / 60
            seconds = build.duration % 60
            "#{minutes}m #{seconds}s"
          end

          def commit_message_block
            {
              type: 'TextBlock',
              text: commit.message&.split("\n")&.first || 'No commit message',
              wrap: true,
              spacing: 'Medium'
            }
          end

          def simple_actions
            actions = [{
              type: 'Action.OpenUrl',
              title: 'View Build',
              url: build_url
            }]

            if commit.compare_url
              actions << {
                type: 'Action.OpenUrl',
                title: 'View Commit',
                url: commit.compare_url
              }
            end

            {
              type: 'ActionSet',
              actions:
            }
          end

          def status_emoji
            case build.state.to_s
            when 'passed' then '✅'
            when 'failed' then '❌'
            when 'errored' then '⚠️'
            when 'canceled' then '🚫'
            else '❓'
            end
          end

          def card_body
            [
              header_section,
              narrow_header,
              very_narrow_header,
              pull_request_section,
              metadata_section,
              narrow_metadata,
              commit_message_section,
              action_buttons
            ].compact
          end

          def header_section
            {
              type: 'ColumnSet',
              columns: [
                {
                  type: 'Column',
                  width: 'auto',
                  horizontalAlignment: 'Left',
                  items: [status_badge('ExtraLarge')]
                },
                {
                  type: 'Column',
                  width: 'stretch',
                  items: [repository_name_large],
                  verticalContentAlignment: 'Center'
                },
                {
                  type: 'Column',
                  width: 'auto',
                  items: [timestamp_text],
                  verticalContentAlignment: 'Center',
                  horizontalAlignment: 'Right'
                }
              ],
              spacing: 'Small',
              horizontalAlignment: 'Left',
              targetWidth: 'AtLeast:Standard'
            }
          end

          def narrow_header
            {
              type: 'Container',
              items: [
                timestamp_text,
                {
                  type: 'ColumnSet',
                  columns: [
                    {
                      type: 'Column',
                      width: 'auto',
                      items: [status_badge('Large')]
                    },
                    {
                      type: 'Column',
                      width: 'stretch',
                      items: [repository_name_large],
                      verticalContentAlignment: 'Center'
                    }
                  ]
                }
              ],
              targetWidth: 'Narrow'
            }
          end

          def very_narrow_header
            {
              type: 'Container',
              items: [
                timestamp_text,
                status_badge('Large', spacing: 'ExtraSmall'),
                repository_name_medium
              ],
              targetWidth: 'VeryNarrow'
            }
          end

          def pull_request_section
            return nil unless pull_request_text

            {
              type: 'ColumnSet',
              columns: [
                {
                  type: 'Column',
                  width: 'stretch',
                  items: [
                    {
                      type: 'TextBlock',
                      text: pull_request_text,
                      wrap: true,
                      size: 'Default',
                      weight: 'Bolder',
                      height: 'stretch',
                      maxLines: 1,
                      horizontalAlignment: 'Left'
                    }
                  ]
                }
              ],
              spacing: 'Medium',
              horizontalAlignment: 'Left'
            }
          end

          def metadata_section
            {
              type: 'ColumnSet',
              spacing: 'ExtraLarge',
              columns: [
                commit_column,
                branch_column,
                author_column
              ],
              targetWidth: 'AtLeast:Narrow',
              horizontalAlignment: 'Left'
            }
          end

          def narrow_metadata
            {
              type: 'Container',
              items: [
                metadata_item('Commit', 'Flow', commit_sha),
                metadata_item('Branch', 'Branch', branch_name),
                metadata_item('Author', 'Person', author_name)
              ].flatten,
              targetWidth: 'VeryNarrow'
            }
          end

          def commit_message_section
            {
              type: 'ColumnSet',
              columns: [
                {
                  type: 'Column',
                  width: 'stretch',
                  items: [
                    {
                      type: 'TextBlock',
                      text: 'Commit Message',
                      wrap: true,
                      size: 'Small',
                      color: 'Default',
                      isSubtle: true
                    },
                    {
                      type: 'TextBlock',
                      text: commit_message,
                      wrap: true,
                      spacing: 'ExtraSmall',
                      size: 'Small',
                      weight: 'Bolder',
                      maxLines: 0
                    }
                  ]
                }
              ],
              spacing: 'ExtraLarge',
              horizontalAlignment: 'Left'
            }
          end

          def action_buttons
            {
              type: 'ActionSet',
              spacing: 'ExtraLarge',
              actions: [
                {
                  type: 'Action.OpenUrl',
                  title: 'View Build',
                  url: build_url,
                  style: 'positive'
                },
                compare_action
              ].compact
            }
          end

          # Helper methods for card elements

          def status_badge(size, spacing: nil)
            badge = {
              type: 'Badge',
              text: status_text,
              size:,
              style: status_style,
              appearance: 'Tint',
              icon: status_icon,
              horizontalAlignment: 'Left'
            }
            badge[:spacing] = spacing if spacing
            badge
          end

          def repository_name_large
            {
              type: 'TextBlock',
              text: repository_slug,
              wrap: true,
              size: 'Large',
              weight: 'Bolder',
              maxLines: 1,
              horizontalAlignment: 'Left'
            }
          end

          def repository_name_medium
            {
              type: 'TextBlock',
              text: repository_slug,
              wrap: true,
              size: 'Medium',
              weight: 'Bolder',
              horizontalAlignment: 'Left',
              maxLines: 1,
              spacing: 'Small'
            }
          end

          def timestamp_text
            {
              type: 'TextBlock',
              text: time_ago,
              wrap: true,
              isSubtle: true,
              size: 'Small',
              targetWidth: 'AtLeast:Narrow',
              horizontalAlignment: 'Right'
            }
          end

          def commit_column
            {
              type: 'Column',
              width: 'auto',
              items: [
                {
                  type: 'TextBlock',
                  text: 'Commit',
                  wrap: true,
                  size: 'Small',
                  weight: 'Bolder'
                },
                metadata_with_icon('Flow', commit_sha)
              ],
              verticalContentAlignment: 'Center'
            }
          end

          def branch_column
            {
              type: 'Column',
              width: 'auto',
              items: [
                {
                  type: 'TextBlock',
                  text: 'Branch',
                  wrap: true,
                  size: 'Small',
                  weight: 'Bolder'
                },
                metadata_with_icon('Branch', branch_name)
              ],
              verticalContentAlignment: 'Center',
              spacing: 'ExtraLarge'
            }
          end

          def author_column
            {
              type: 'Column',
              width: 'auto',
              items: [
                {
                  type: 'TextBlock',
                  text: 'Author',
                  wrap: true,
                  size: 'Small',
                  weight: 'Bolder'
                },
                metadata_with_icon('Person', author_name)
              ],
              spacing: 'ExtraLarge'
            }
          end

          def metadata_with_icon(icon_name, text)
            {
              type: 'ColumnSet',
              columns: [
                {
                  type: 'Column',
                  width: 'auto',
                  items: [
                    {
                      type: 'Icon',
                      name: icon_name,
                      size: 'xxSmall'
                    }
                  ]
                },
                {
                  type: 'Column',
                  width: 'stretch',
                  items: [
                    {
                      type: 'TextBlock',
                      text:,
                      wrap: true,
                      size: 'Small',
                      maxLines: 1,
                      isSubtle: true
                    }
                  ],
                  spacing: 'ExtraSmall',
                  verticalContentAlignment: 'Center'
                }
              ],
              spacing: 'ExtraSmall'
            }
          end

          def metadata_item(label, icon_name, value)
            [
              {
                type: 'TextBlock',
                text: label,
                wrap: true,
                size: 'Small',
                weight: 'Bolder',
                color: 'Default',
                horizontalAlignment: 'Left',
                maxLines: 1
              },
              {
                type: 'ColumnSet',
                columns: [
                  {
                    type: 'Column',
                    width: 'auto',
                    items: [
                      {
                        type: 'Icon',
                        name: icon_name,
                        size: 'xxSmall'
                      }
                    ]
                  },
                  {
                    type: 'Column',
                    width: 'stretch',
                    spacing: 'ExtraSmall',
                    items: [
                      {
                        type: 'TextBlock',
                        text: value,
                        wrap: true,
                        size: 'Small',
                        color: 'Default',
                        isSubtle: true,
                        maxLines: 1
                      }
                    ],
                    horizontalAlignment: 'Left'
                  }
                ],
                spacing: 'ExtraSmall'
              }
            ]
          end

          def compare_action
            return nil unless commit.compare_url

            {
              type: 'Action.OpenUrl',
              title: 'Compare',
              url: commit.compare_url
            }
          end

          # Data extraction methods

          def status_text
            case build.state.to_s
            when 'passed'
              'Passed'
            else
              'Failed'
            end
          end

          def status_style
            case build.state.to_s
            when 'passed'
              'Good'
            else
              'Attention'
            end
          end

          def status_icon
            case build.state.to_s
            when 'passed'
              'CheckmarkCircle'
            else
              'ErrorCircle'
            end
          end

          def repository_slug
            repository.slug
          end

          def commit_sha
            commit.commit[0..6] # Short SHA
          end

          def branch_name
            commit.branch
          end

          def author_name
            commit.author_name
          end

          def commit_message
            commit.message
          end

          def pull_request_text
            return nil unless build.pull_request?

            "Pull request ##{build.pull_request_number}"
          end

          def build_url
            # Construct build URL based on repository and build number
            "https://app.travis-ci.com/#{repository.slug}/builds/#{build.id}"
          end

          def time_ago
            return 'just now' unless build.finished_at

            seconds = Time.now - build.finished_at
            case seconds
            when 0..59
              'just now'
            when 60..3599
              "#{(seconds / 60).to_i} minutes ago"
            when 3600..86_399
              "#{(seconds / 3600).to_i} hours ago"
            else
              "#{(seconds / 86_400).to_i} days ago"
            end
          end
        end
      end
    end
  end
end
