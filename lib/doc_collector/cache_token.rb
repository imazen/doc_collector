module DocCollector
  class CacheToken
    attr_reader :source_commit
    attr_reader :collector_version
    attr_reader :cache_breaker
  end
end
