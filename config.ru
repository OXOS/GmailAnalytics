require 'bundler/setup'

require 'sinatra'

require File.expand_path(File.dirname(__FILE__) + '/gmail_leads_stats')

get "/stats" do
<<-EOS
<html>
<form method='post'>
  <p>
    <label>
      Login:<br />
      <input name='login' />
    </label>
  </p>
  <p>
    <label>
      Password:<br />
      <input name='password' type='password' />
    </label>
  </p>
  <p>
    <label>
      Number of days:<br />
      <input name='days' />
    </label>
    <br />
    <small>Leave blank to process entire mailbox</small>
  </p>
  <p>
    <input type='submit' value='Analyze!'/>
  </p>
</form>
</html>
EOS
end

post "/stats" do
  report = GmailAnalytics.run( params[:login], params[:password], params[:days] )
  "<pre>" + report + "</pre>"
end

set :show_exceptions, true
run Sinatra::Application

