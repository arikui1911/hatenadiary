require 'mechanize'

class HatenaDiary
  def self.login(*args)
    client = new(*args)
    return unless block_given?
    client.login
    begin
      yield client
    ensure
      client.logout
    end
  end

  def initialize(username, password,
                 groupname: nil, read_timeout_sec: nil, user_agent_alias: nil,
                 http_proxy: nil, cookie_file_path: nil,
                 hatena_encoding: Encoding::UTF_8)
    @username = username
    @password = password
    if groupname
      @groupname = groupname
      extend GroupDiary
    end
    @agent                  = Mechanize.new
    @agent.read_timeout     = read_timeout_sec if read_timeout_sec
    @agent.user_agent_alias = user_agent_alias if user_agent_alias
    @agent.set_proxy(*http_proxy) if http_proxy
    @cookie_file = cookie_file_path
    @encoding    = hatena_encoding
    @login_p = false
  end

  def inspect
    "#<HatenaDiary:#{@username}>"
  end

  def login?
    @login_p
  end

  def login
    if @cookie_file
      @agent.cookie_jar.load @cookie_file
    else
      try_login
    end
    @login_p = true
  end

  private def try_login
    form = @agent.get("https://www.hatena.ne.jp/login").forms.first
    form["name"]       = @username
    form["password"]   = @password
    form["persistent"] = "true"
    response = form.submit
    case response.title
    when "Hatena" then response
    when "Login - Hatena" then login_error("login failure")
    else raise Exception, '[HatenaDiary][BUG] must not happen (maybe cannot follow hatena spec)'
    end
  end

  def logout
    if @cookie_file
      @agent.cookie_jar.save @cookie_file
    else
      @agent.get("https://www.hatena.ne.jp/logout")   # logout
    end
    @login_p = false
  end

  def post(yyyy, mm, dd, title, body, trivial: false)
    login_error "not logined yet" unless login?
    form = edit_form(yyyy, mm, dd){|r| r.form_with(name: 'edit') }
    form["year"]    = "%04d" % yyyy
    form["month"]   = "%02d" % mm
    form["day"]     = "%02d" % dd
    form["title"]   = title.encode(@encoding)
    form["body"]    = body.encode(@encoding)
    form["trivial"] = "true" if trivial
    @agent.submit form, form.button_with(name: 'edit')
  end

  def delete(yyyy, mm, dd)
    login_error "not logined yet" unless login?
    edit_form(yyyy, mm, dd){|r| r.forms.last }.submit
  end

  private

  def edit_form(yyyy, mm, dd)
    yield @agent.get(edit_url(yyyy, mm, dd))
  end

  def edit_url(yyyy, mm, dd)
    sprintf "http://d.hatena.ne.jp/%s/edit?date=%04d%02d%02d", @username, yyyy, mm, dd
  end

  def login_error(msg)
    raise LoginError.new(msg, @username)
  end

  module GroupDiary
    def inspect
      "#<HatenaDiary:#{@groupname}:#{@username}>"
    end

    private

    def login_error(msg)
      LoginError.new(msg, @username, @groupname)
    end

    def edit_url(yyyy, mm, dd)
      sprintf "http://%s.g.hatena.ne.jp/%s/edit?date=%04d%02d%02d", @groupname, @username, yyyy, mm, dd
    end
  end

  class LoginError < RuntimeError
    def initialize(msg, username, groupname = nil)
      super [groupname, username, msg].compact.join(': ')
      @username  = username
      @groupname = groupname
    end

    attr_reader :username, :groupname
  end
end
