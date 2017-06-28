require 'spec_helper'

describe Travis::Addons::Config, 'for webhooks' do
  let(:type)    { :webhooks }
  let(:build)   { FactoryGirl.build(:build) }
  let(:payload) { Travis::Addons::Serializer::Tasks::Build.new(build).data }
  let(:config)  { described_class.new(payload) }

  describe 'send_on_finished_for?' do
    # previous | current | config[:notifications] | result
    combinations = [
      [nil,     :passed, { on_success: 'always' }, true  ],
      [nil,     :passed, { on_success: 'change' }, true  ],
      [nil,     :passed, { on_success: 'never'  }, false ],
      [nil,     :passed, { on_failure: 'always' }, true  ],
      [nil,     :passed, { on_failure: 'change' }, true  ],
      [nil,     :passed, { on_failure: 'never'  }, true  ],

      [nil,     :failed, { on_success: 'always' }, true  ],
      [nil,     :failed, { on_success: 'change' }, true  ],
      [nil,     :failed, { on_success: 'never'  }, true  ],
      [nil,     :failed, { on_failure: 'always' }, true  ],
      [nil,     :failed, { on_failure: 'change' }, true  ],
      [nil,     :failed, { on_failure: 'never'  }, false ],

      [:passed, :passed, { on_success: 'always' }, true  ],
      [:passed, :passed, { on_success: 'change' }, false ],
      [:passed, :passed, { on_success: 'never'  }, false ],
      [:passed, :passed, { on_failure: 'always' }, true  ],
      [:passed, :passed, { on_failure: 'change' }, true  ],
      [:passed, :passed, { on_failure: 'never'  }, true  ],

      [:passed, :failed, { on_success: 'always' }, true  ],
      [:passed, :failed, { on_success: 'change' }, true  ],
      [:passed, :failed, { on_success: 'never'  }, true  ],
      [:passed, :failed, { on_failure: 'always' }, true  ],
      [:passed, :failed, { on_failure: 'change' }, true  ],
      [:passed, :failed, { on_failure: 'never'  }, false ],

      [:failed, :passed, { on_success: 'always' }, true  ],
      [:failed, :passed, { on_success: 'change' }, true  ],
      [:failed, :passed, { on_success: 'never'  }, false ],
      [:failed, :passed, { on_failure: 'always' }, true  ],
      [:failed, :passed, { on_failure: 'change' }, true  ],
      [:failed, :passed, { on_failure: 'never'  }, true  ],

      [:failed, :failed, { on_success: 'always' }, true  ],
      [:failed, :failed, { on_success: 'change' }, true  ],
      [:failed, :failed, { on_success: 'never'  }, true  ],
      [:failed, :failed, { on_failure: 'always' }, true  ],
      [:failed, :failed, { on_failure: 'change' }, false ],
      [:failed, :failed, { on_failure: 'never'  }, false ],
    ]

    combinations.each do |previous, current, notifications, result|
      it "returns #{result.inspect.ljust(5)} if previous_state is #{"#{previous.inspect},".ljust(8)} the current state is #{current.inspect}, and config[:notifications] is #{notifications}" do
        build.stubs(
          config: build.config.deep_merge(notifications: notifications),
          state: current,
          previous_state: previous
        )
        expect(config.send_on?(type, :finished)).to eql(result)
      end
    end
  end
end
