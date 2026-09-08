module RightSignals
  # Record ids are UUIDv7 strings, but older server versions returned integers.
  # Accepting either keeps the SDK working across both rather than raising
  # `Expected Int but was String` on every response.
  module IdConverter
    def self.from_json(pull : JSON::PullParser) : String
      case pull.kind
      when .string?
        pull.read_string
      when .int?
        pull.read_int.to_s
      else
        pull.raise "Expected String or Int for id, got #{pull.kind}"
      end
    end

    def self.to_json(value : String, json : JSON::Builder) : Nil
      json.string(value)
    end
  end

  # As IdConverter, for optional id fields.
  module NilableIdConverter
    def self.from_json(pull : JSON::PullParser) : String?
      return pull.read_null if pull.kind.null?
      IdConverter.from_json(pull)
    end

    def self.to_json(value : String?, json : JSON::Builder) : Nil
      if value
        json.string(value)
      else
        json.null
      end
    end
  end
end
