# We have keys with this semantical meaning:
#
#   1.1.1.1 \
#             1.1.2.1         3.1
#   1.1.1.2 /         \     /
#                       2.1
#                     /     \
#   1.2.1.1 - 1.2.2.1         3.2
#
# In other words:
#
#   1.1.1.1   start 1.1.1.1, 1.1.1.2, and 1.2.1.1 in parallel
#   1.1.1.2
#   1.1.2.1   start once 1.1.1.1 and 1.1.1.2 have completed
#   1.2.1.1
#   1.2.2.1   start once 1.2.1.1 has completed
#   2         start once 1.1.2.1 and 1.2.2.1 have completed
#   3.1       start 3.1 and 3.2 once 2 has completed
#   3.2
#
# We transform this into a tree structure like the following, dropping: all
# jobs that are not in a startable state (i.e. `created`).
#
#   1
#     1.1
#       1.1.1
#         1.1.1.1
#         1.1.1.2
#     1.2
#       1.2.1
#         1.2.1.1
#       1.2.2
#         1.2.2.1
#   2
#     2.1
#   3
#     3.1
#     3.2
#
# Then, in order to determine startable jobs we can:
#
# * Select the first branch
# * From this branch select all first branches (1.1.1 and 1.2.1)
# * From these branches select all leafs
#
# This mechanism doesn't seem overly generic, but I cannot come up with any other
# way that would not
#
# * either not select 1.2.1.1 as startable (when all jobs are :created)
# * or not exclude 1.2.2.1 from being startable
#
# If anyone can come up with a more generic mechanism then I'd be extremely
# happy to hear it :)

module Travis
  module Hub
    module Stages
      class Stage
        class Job < Struct.new(:state, :key)
          def leaf?
            nums.size == 1
          end

          def parent_key
            key.split('.')[0..-2].join('.')
          end

          def nums
            @nums ||= key.split('.').map(&:to_i)
          end

          def startable
            startable? ? [self] : []
          end

          def startable?
            state == :created
          end

          def finished?
            state == :finished
          end

          def inspect
            "Job key=#{key} state=#{state}"
          end
        end

        def self.build(jobs)
          jobs.inject(new(nil, 0)) do |stage, job|
            job = Job.new(*job.values)
            stage << job unless job.finished?
            stage
          end
        end

        attr_reader :parent, :num, :children

        def initialize(parent, num)
          @parent   = parent
          @num      = num.to_i
          @children = []
        end

        def <<(job)
          node = job.leaf? ? children : stage(job.nums.shift)
          node << job
        end

        def startable
          if first.is_a?(Stage)
            first.children.map(&:startable).flatten
          else
            children.select(&:startable?).map(&:to_h)
          end
        end

        def flatten
          children.map { |child| child.is_a?(Stage) ? child.flatten : child }.flatten
        end

        def root?
          key == '0'
        end

        def key
          [parent && parent.key != '0' ? parent.key : nil, num].compact.join('.')
        end

        def inspect
          indent = ->(child) { child.inspect.split("\n").map { |str| "  #{str}" }.join("\n") }
          "#{root? ? 'Root' : "Stage key=#{key}"}\n#{children.map(&indent).join("\n")}"
        end

        private

          def stage(num)
            stages.detect { |stage| stage.num == num } || add_stage(num)
          end

          def add_stage(num)
            Stage.new(self, num.to_i).tap { |stage| children << stage }
          end

          def stages
            children.select { |child| child.is_a?(Stage) }
          end

          def first
            children.first
          end
      end
    end
  end
end
