{}: {
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    config = {
      homeassistant = {
        name = "Home Assistant";
        #51.203108, 4.769569
        latitude = "51.203108";
        longitude = "4.769569";
        unit_system = "metric";
        time_zone = "Europe/Brussels";
        temperature_unit = "C";
      };
    };
  };
}
