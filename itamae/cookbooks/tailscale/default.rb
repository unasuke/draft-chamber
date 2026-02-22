package "curl"
execute "curl -fsSL https://tailscale.com/install.sh | sh" do
  not_if "which tailscale"
end
service "tailscaled" do
  action [ :enable, :start ]
end
