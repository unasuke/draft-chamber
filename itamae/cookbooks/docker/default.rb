include_recipe "docker::install"

service "docker"

remote_file "/etc/docker/daemon.json" do
  notifies :restart, "service[docker]"
end

execute "ensure kamal network with ipv6 enabled" do
  command "docker network create --ipv6 kamal"
  not_if "docker network inspect kamal | grep '\"EnableIPv6\": true'"
end
