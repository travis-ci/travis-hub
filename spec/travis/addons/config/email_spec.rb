require 'spec_helper'

describe Travis::Addons::Config, 'for emails' do
  let(:build) { FactoryGirl.build(:build) }
  let(:type)  { :email }

  subject { described_class.new(build, config) }

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
      [:passed, :passed, { on_failure: 'always' }, false ],
      [:passed, :passed, { on_failure: 'change' }, false ],
      [:passed, :passed, { on_failure: 'never'  }, false ],

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
      context do
        let(:config) { notifications }

        before { build.stubs(state: current, previous_state: previous) }

        it "returns #{result.inspect.ljust(5)} if previous_state is #{"#{previous.inspect},".ljust(8)} current state is #{current.inspect}, and config[:notifications] is #{notifications}" do
          expect(subject.send_on?(type, :finished)).to be result
        end
      end
    end
  end
end
