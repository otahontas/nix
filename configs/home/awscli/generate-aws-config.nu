#!/usr/bin/env nu

def main [pass_bin: string] {
  let config = ^$pass_bin show aws/config

  mkdir ~/.aws
  $config | save -f ~/.aws/config

  print "AWS config generated successfully at ~/.aws/config"
}
