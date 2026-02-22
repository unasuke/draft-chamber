execute "reload and restart ssh" do
  action :nothing
  command "sudo systemctl daemon-reload && sudo systemctl restart ssh.socket"
end

file "/etc/ssh/sshd_config" do
  action :edit
  block do |content|
    content.gsub!(%r{\A#Port 22}, "Port 9922")
  end
  not_if "grep 'Port 9922' /etc/ssh/sshd_config"
  notifies :run, "execute[reload and restart ssh]"
end
