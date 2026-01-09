_: {
  launchd.agents = {
    lulu = {
      enable = true;
      config = {
        Label = "com.otahontas.autostart.lulu";
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "LuLu"
        ];
        RunAtLoad = true;
      };
    };

    blockblock = {
      enable = true;
      config = {
        Label = "com.otahontas.autostart.blockblock";
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "BlockBlock Helper"
        ];
        RunAtLoad = true;
      };
    };
  };
}
