# vim: ft=sh:

@test "bind is running" {
  if [ -f /etc/debian_version ]; then
    service bind9 status
  elif [ -f /etc/redhat-release ]; then
    service named status
  fi
}

@test "bind returns staticly confgured ip address" {
  dig +short @localhost test1.test | grep 10.0.2.123
}
