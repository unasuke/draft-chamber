package "fail2ban"
service "fail2ban" do
  action [ :enable, :start ]
end
