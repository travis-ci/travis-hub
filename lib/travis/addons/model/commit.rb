class Commit < ActiveRecord::Base
  def pull_request?
    ref =~ %r(^refs/pull/(\d+)/merge$)
  end

  def pull_request_number
    match = ref.match(%r(^refs/pull/(\d+)/merge$))
    match && match[1].to_i
  end

  def tag_name
    ref =~ %r(^refs/tags/(.*?)$) && $1
  end
end
