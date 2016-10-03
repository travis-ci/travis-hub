module Support
  module Stages
    def startable
      root.startable.map(&:values).map(&:last)
    end

    def start(*stages)
      stages.each { |stage|jobs[index(stage)][:state] = :started }
    end

    def finish(*stages)
      stages.each { |stage|jobs[index(stage)][:state] = :finished }
    end

    def index(stage)
      keys.index { |key| key == stage }
    end
  end
end
