class TodoistClient
  BASE_URL = "https://api.todoist.com/api/v1".freeze

  def initialize(token)
    @token = token
  end

  def create_task(content:, description: nil, project_id: nil, due_date: nil)
    body = { content: content }
    body[:description] = description if description
    body[:project_id] = project_id if project_id
    body[:due_date] = due_date if due_date
    post("tasks", body)
  end

  def update_task(task_id, content: nil, description: nil, due_date: nil)
    body = {}
    body[:content] = content if content
    body[:description] = description if description
    body[:due_date] = due_date if due_date
    post("tasks/#{task_id}", body)
  end

  def projects
    results = []
    cursor = nil
    loop do
      params = { limit: 200 }
      params[:cursor] = cursor if cursor
      data = get("projects", params)
      results.concat(data["results"] || [])
      cursor = data["next_cursor"]
      break if cursor.nil?
    end
    results
  end

  def validate_token!
    get("projects", { limit: 1 })
    true
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.options.timeout = 10
      f.options.open_timeout = 5
    end
  end

  def headers
    { "Authorization" => "Bearer #{@token}" }
  end

  def post(path, body)
    response = connection.post(path, body, headers)
    handle_response(response)
  end

  def get(path, params = {})
    response = connection.get(path, params, headers)
    handle_response(response)
  end

  def handle_response(response)
    case response.status
    when 200, 201, 204
      response.body
    when 401
      raise AuthenticationError, "Ungültiger Todoist API-Token."
    when 403
      raise StandardError, "Zugriff verweigert."
    when 404
      raise StandardError, "Todoist-Ressource nicht gefunden."
    else
      raise StandardError, "Todoist API Fehler (#{response.status}): #{response.body}"
    end
  end

  class AuthenticationError < StandardError; end
end
