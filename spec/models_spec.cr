require "./spec_helper"

describe RightSignals::TraceSummary do
  it "deserializes from JSON" do
    json = %|{"id":1,"trace_id":"abc123","service":"my-svc","environment":"production","release":"1.0","root_span":"GET /users","duration":"1.5s","span_count":5,"started_at":"2026-03-11T10:00:00Z"}|
    trace = RightSignals::TraceSummary.from_json(json)
    trace.id.should eq "1"
    trace.trace_id.should eq "abc123"
    trace.service.should eq "my-svc"
    trace.span_count.should eq 5
  end

  it "deserializes a UUID id" do
    json = %|{"id":"01a07f27-f10c-7c11-abe6-0d964f9f10e9","trace_id":"abc123","service":"my-svc","span_count":5}|
    trace = RightSignals::TraceSummary.from_json(json)
    trace.id.should eq "01a07f27-f10c-7c11-abe6-0d964f9f10e9"
  end

  it "handles nil optional fields" do
    json = %|{"id":1,"trace_id":"abc","service":"svc","span_count":1}|
    trace = RightSignals::TraceSummary.from_json(json)
    trace.environment.should be_nil
    trace.release.should be_nil
  end
end

describe RightSignals::IssueSummary do
  it "deserializes from JSON" do
    json = %|{"id":2,"summary":"RuntimeError: boom","exception_type":"RuntimeError","service":"svc","environment":"prod","status":"open","regressed":false,"occurrence_count":3,"first_release":"1.0","last_release":"1.1","first_seen_at":"2026-03-10T10:00:00Z","last_seen_at":"2026-03-11T10:00:00Z"}|
    issue = RightSignals::IssueSummary.from_json(json)
    issue.id.should eq "2"
    issue.exception_type.should eq "RuntimeError"
    issue.status.should eq "open"
    issue.regressed.should eq false
    issue.occurrence_count.should eq 3
  end

  it "deserializes a UUID id" do
    json = %|{"id":"019fba62-5867-7c79-9622-2d6c8ea12d73","summary":"boom","exception_type":"RuntimeError","service":"svc","status":"open","regressed":false,"occurrence_count":1}|
    issue = RightSignals::IssueSummary.from_json(json)
    issue.id.should eq "019fba62-5867-7c79-9622-2d6c8ea12d73"
  end

  it "round-trips an id back to JSON as a string" do
    json = %|{"id":"019fba62-5867-7c79-9622-2d6c8ea12d73","summary":"boom","exception_type":"RuntimeError","service":"svc","status":"open","regressed":false,"occurrence_count":1}|
    issue = RightSignals::IssueSummary.from_json(json)
    issue.to_json.should contain %|"id":"019fba62-5867-7c79-9622-2d6c8ea12d73"|
  end
end

describe RightSignals::IssueDetail do
  it "deserializes with stack trace and occurrences" do
    json = %|{"id":2,"summary":"RuntimeError","exception_type":"RuntimeError","service":"svc","status":"open","regressed":false,"occurrence_count":1,"stack_trace":"app.rb:42","recent_occurrences":[{"id":10,"exception_type":"RuntimeError","message":"boom","occurred_at":"2026-03-11T10:00:00Z"}]}|
    issue = RightSignals::IssueDetail.from_json(json)
    issue.stack_trace.should eq "app.rb:42"
    issue.recent_occurrences.size.should eq 1
    issue.recent_occurrences[0].message.should eq "boom"
  end

  it "deserializes UUID ids in nested occurrences" do
    json = %|{"id":"01a0778b-2006-79e1-8559-0b98348c2f51","summary":"RuntimeError","exception_type":"RuntimeError","service":"svc","status":"open","regressed":false,"occurrence_count":1,"recent_occurrences":[{"id":"01a07f38-0170-7355-a3bf-e351190baa7e","exception_type":"RuntimeError","trace_id":"01a07f3a-3059-7900-b060-1de1874dbb96"}]}|
    issue = RightSignals::IssueDetail.from_json(json)
    issue.id.should eq "01a0778b-2006-79e1-8559-0b98348c2f51"
    issue.recent_occurrences[0].id.should eq "01a07f38-0170-7355-a3bf-e351190baa7e"
    issue.recent_occurrences[0].trace_id.should eq "01a07f3a-3059-7900-b060-1de1874dbb96"
  end

  it "leaves an absent nested trace_id nil" do
    json = %|{"id":"01a0778b-2006-79e1-8559-0b98348c2f51","summary":"E","exception_type":"E","service":"svc","status":"open","regressed":false,"occurrence_count":1,"recent_occurrences":[{"id":"01a07f38-0170-7355-a3bf-e351190baa7e","exception_type":"E","trace_id":null}]}|
    issue = RightSignals::IssueDetail.from_json(json)
    issue.recent_occurrences[0].trace_id.should be_nil
  end
end

describe RightSignals::OccurrenceSummary do
  it "deserializes UUID ids" do
    json = %|{"id":"01a07f38-0170-7355-a3bf-e351190baa7e","exception_type":"Net::OpenTimeout","message":"boom","service":"softcover","issue_id":"01a04372-5249-7812-8847-85dda3afc509","issue_summary":"Net::OpenTimeout","trace_id":"01a07f3a-3059-7900-b060-1de1874dbb96","occurred_at":"2026-09-08T10:00:00Z"}|
    occ = RightSignals::OccurrenceSummary.from_json(json)
    occ.id.should eq "01a07f38-0170-7355-a3bf-e351190baa7e"
    occ.issue_id.should eq "01a04372-5249-7812-8847-85dda3afc509"
    occ.trace_id.should eq "01a07f3a-3059-7900-b060-1de1874dbb96"
  end
end

describe RightSignals::TraceDetail do
  it "deserializes with spans" do
    json = %|{"id":1,"trace_id":"abc","service":"svc","span_count":1,"spans":[{"span_id":"s1","operation":"GET /","kind":2,"status_code":1,"duration":"50ms","started_at":"2026-03-11T10:00:00Z"}]}|
    trace = RightSignals::TraceDetail.from_json(json)
    trace.spans.size.should eq 1
    trace.spans[0].operation.should eq "GET /"
  end

  it "deserializes UUID ids in span occurrences" do
    json = %|{"id":"01a07f6e-613c-7407-b5cc-78324ead7e33","trace_id":"abc","service":"svc","span_count":1,"spans":[{"span_id":"s1","operation":"GET /","occurrences":[{"id":"01a07f38-0170-7355-a3bf-e351190baa7e","exception_type":"RuntimeError","message":"boom"}]}]}|
    trace = RightSignals::TraceDetail.from_json(json)
    trace.id.should eq "01a07f6e-613c-7407-b5cc-78324ead7e33"
    trace.spans[0].occurrences.not_nil![0].id.should eq "01a07f38-0170-7355-a3bf-e351190baa7e"
  end
end

describe RightSignals::EventSummary do
  it "deserializes from JSON" do
    json = %|{"id":5,"event_name":"api_request","service":"cowork","release":"1.0","user_email":"test@example.com","prompt_id":"abc-123","session_id":"sess-1","timestamp":"2026-03-11T10:00:00Z"}|
    event = RightSignals::EventSummary.from_json(json)
    event.event_name.should eq "api_request"
    event.user_email.should eq "test@example.com"
  end

  it "deserializes a UUID id" do
    json = %|{"id":"01a07f38-0170-7355-a3bf-e351190baa7e","event_name":"api_request","service":"cowork"}|
    event = RightSignals::EventSummary.from_json(json)
    event.id.should eq "01a07f38-0170-7355-a3bf-e351190baa7e"
  end
end

describe RightSignals::IdConverter do
  it "rejects a type that is neither string nor int" do
    json = %|{"id":{"nested":true},"trace_id":"abc","service":"svc","span_count":1}|
    expect_raises(JSON::ParseException) do
      RightSignals::TraceSummary.from_json(json)
    end
  end
end

describe RightSignals::Client do
  it "initializes with defaults" do
    client = RightSignals::Client.new
    client.base_url.should eq "https://app.rightsignals.com"
    client.token.should eq ""
  end

  it "accepts custom base_url and token" do
    client = RightSignals::Client.new(base_url: "http://localhost:3000", token: "rsg_test")
    client.base_url.should eq "http://localhost:3000"
    client.token.should eq "rsg_test"
  end
end
