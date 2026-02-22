package "unbound"
service "unbound" do
  action [ :enable, :start ]
  user "root"
end

remote_file "/etc/unbound/unbound.conf.d/dns64-forward.conf" do
  notifies :restart, "service[unbound]"
  owner "root"
  group "root"
end
