# coding: utf-8
require 'test-unit'
require 'flexmock/test_unit'
require 'hatenadiary'
require 'hatenadiary/version'

class TestHatenaDiary < Test::Unit::TestCase
  setup do
    @username = "USERNAME"
    @password = "PASSWORD"
    @agent = flexmock("agent")
    flexmock(Mechanize, new: @agent)
  end

  test "some keyword args of #initialize" do
    @agent.should_receive(:read_timeout=).with(123)
    @agent.should_receive(:user_agent_alias=).with("UA")
    @agent.should_receive(:set_proxy).with("http://example.com", 1234)
    HatenaDiary.new(@username, @password,
                    read_timeout_sec: 123,
                    user_agent_alias: "UA",
                    http_proxy:       ["http://example.com", 1234])
  end

  sub_test_case "cookie" do
    setup do
      @cookie_file = 'path/to/cookie.txt'
      @cookie_jar  = flexmock("cookie_jar")
      @agent.should_receive(:cookie_jar).and_return(@cookie_jar)
      @client = HatenaDiary.new(@username, @password, cookie_file_path: @cookie_file)
    end

    test "#login" do
      @cookie_jar.should_receive(:load).with(@cookie_file)
      @client.login
      assert @client.login?
    end

    test "#logout" do
      @cookie_jar.should_receive(:save).with(@cookie_file)
      @client.logout
      assert !@client.login?
    end
  end

  sub_test_case "encoding" do
    setup do
      @hatena_encoding = 'euc-jp'
      @client = HatenaDiary.new(@username, @password, hatena_encoding: @hatena_encoding)
      ready_mock_post "d", "12340506"
    end

    test "#post" do
      @form.should_receive(:[]=).with("year",  "1234").once
      @form.should_receive(:[]=).with("month", "05").once
      @form.should_receive(:[]=).with("day",   "06").once
      @form.should_receive(:[]=).with("title", "タイトル".encode(@hatena_encoding)).once
      @form.should_receive(:[]=).with("body",  "本文".encode(@hatena_encoding)).once
      @client.login
      @client.post 1234, 5, 6, "タイトル", "本文"
    end
  end

  sub_test_case "normal diary" do
    setup do
      @client = HatenaDiary.new(@username, @password)
    end

    sub_test_case "#login" do
      test "login and logout" do
        ready_mock_login "Hatena"
        @agent.should_receive(:get).with("https://www.hatena.ne.jp/logout")
        assert !@client.login?
        @client.login
        assert @client.login?
        @client.logout
        assert !@client.login?
      end

      test "login failure" do
        ready_mock_login "Login - Hatena"
        ex = assert_raise(HatenaDiary::LoginError){ @client.login }
        assert_equal @username, ex.username
        assert_nil   ex.groupname
      end

      test "login error because Hatena HTML was changed" do
        ready_mock_login "*jumbled pagetitle*"
        ex = assert_raise(Exception){ @client.login }
        assert_match /must not happen/, ex.message
      end
    end

    sub_test_case "#post" do
      test "do post" do
        ready_mock_post "d", "12340506"
        @form.should_receive(:[]=).with("year",  "1234").once
        @form.should_receive(:[]=).with("month", "05").once
        @form.should_receive(:[]=).with("day",   "06").once
        @form.should_receive(:[]=).with("title", "TITLE").once
        @form.should_receive(:[]=).with("body",  "BODY").once
        @client.login
        @client.post 1234, 5, 6, "TITLE", "BODY"
      end

      test "trivial post" do
        ready_mock_post "d", "12340506"
        @form.should_receive(:[]=).with("year",    "1234").once
        @form.should_receive(:[]=).with("month",   "05").once
        @form.should_receive(:[]=).with("day",     "06").once
        @form.should_receive(:[]=).with("title",   "TITLE").once
        @form.should_receive(:[]=).with("body",    "BODY").once
        @form.should_receive(:[]=).with("trivial", "true").once
        @client.login
        @client.post 1234, 5, 6, "TITLE", "BODY", trivial: true
      end

      test "post without login" do
        assert_raise HatenaDiary::LoginError do
          @client.post 1999, 5, 26, "TITLE", "BODY"
        end
      end
    end

    sub_test_case "#delete" do
      test "do delete" do
        ready_mock_delete "d", "12340506"
        @client.login
        @client.delete 1234, 5, 6
      end

      test "delete without login" do
        assert_raise HatenaDiary::LoginError do
          @client.delete 2009, 8, 30
        end
      end
    end
  end

  sub_test_case "group diary" do
    setup do
      @groupname = "GROUP"
      @client = HatenaDiary.new(@username, @password, groupname: @groupname)
    end

    test "#post" do
      ready_mock_post "#{@groupname}.g", "12340506"
      @form.should_receive(:[]=).with("year",  "1234").once
      @form.should_receive(:[]=).with("month", "05").once
      @form.should_receive(:[]=).with("day",   "06").once
      @form.should_receive(:[]=).with("title", "TITLE").once
      @form.should_receive(:[]=).with("body",  "BODY").once
      @client.login
      @client.post 1234, 5, 6, "TITLE", "BODY"
    end

    test "#delete" do
      ready_mock_delete "#{@groupname}.g", "12340506"
      @client.login
      @client.delete 1234, 5, 6
    end
  end

  def ready_mock_login(response_page_title)
    login_page = flexmock("login_page")
    form       = flexmock("form")
    response   = flexmock("response")
    @agent.should_receive(:get).with("https://www.hatena.ne.jp/login").and_return(login_page)
    login_page.should_receive(:forms).and_return([form])
    form.should_receive(:[]=).with("name",       @username).once
    form.should_receive(:[]=).with("password",   @password).once
    form.should_receive(:[]=).with("persistent", "true").once
    form.should_receive(:submit).once.and_return(response)
    response.should_receive(:title).and_return(response_page_title)
  end

  def ready_mock_post(host_lead, date_str)
    @edit_page = flexmock("edit_page")
    @form      = flexmock("form")
    @button    = flexmock("button")
    ready_mock_login "Hatena"
    @agent.should_receive(:get).with("http://#{host_lead}.hatena.ne.jp/#{@username}/edit?date=#{date_str}").and_return(@edit_page)
    @edit_page.should_receive(:form_with).with(:name => 'edit').and_return(@form)
    @form.should_receive(:button_with).with(:name => 'edit').and_return(@button)
    @agent.should_receive(:submit).with(@form, @button)
  end

  def ready_mock_delete(host_lead, date_str)
    @edit_page = flexmock("edit_page")
    @form      = flexmock("form")
    @button    = flexmock("button")
    ready_mock_login "Hatena"
    @agent.should_receive(:get).with("http://#{host_lead}.hatena.ne.jp/#{@username}/edit?date=#{date_str}").and_return(@edit_page)
    @edit_page.should_receive(:forms).returns([@form])
    @form.should_receive(:submit)
  end
end

