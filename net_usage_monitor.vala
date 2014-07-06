using Gtk;
using AppIndicator;

public class NetUsageMonitor : Object
{
  static const uint POLL_INTERVAL = 10000;
  static uint64 _current_down_bytes = 0;
  static uint64 _current_up_bytes = 0;
  static Indicator _indicator;

  public static bool set_indicator_label()
  {
    uint64 down_bytes, up_bytes;
    read_network_usage(out down_bytes, out up_bytes);
    if (_current_down_bytes == 0)
    {
      _current_down_bytes = down_bytes;
    }
    if (_current_up_bytes == 0)
    {
      _current_up_bytes = up_bytes;
    }
    _indicator.set_label(format_net_usage(down_bytes, up_bytes), "");
    _current_down_bytes = down_bytes;
    _current_up_bytes = up_bytes;
    return true;
  }

  public static int main(string[] args) 
  {
    Gtk.init(ref args);
    var loop = new MainLoop();   

    _indicator = new Indicator("Network Usage", "network-transmit-receive",
                               IndicatorCategory.APPLICATION_STATUS);
    set_indicator_label();

    _indicator.set_status(IndicatorStatus.ACTIVE);

    var menu = new Gtk.Menu();
    var poll_timer = new TimeoutSource(POLL_INTERVAL);
    poll_timer.set_callback(() => {return set_indicator_label();});
    poll_timer.attach(loop.get_context());

    var exit_item = new Gtk.MenuItem.with_label("Exit");
    exit_item.activate.connect(() => {loop.quit();});
    exit_item.show();
    menu.append(exit_item);
    
    var about_item = new Gtk.MenuItem.with_label("About");
    about_item.activate.connect(() => {show_about();});
    about_item.show();
    menu.append(about_item);

    _indicator.set_menu(menu);
    loop.run();
    return 0;
  }
  
  public static string get_data_string(uint64 bytes)
  {
    string data_string;
    if (bytes < 1024)  // Less than 1K
    {
      data_string = "%lluB".printf(bytes);
    }
    else if (bytes < 102400)  // Less than 100KB
    {
      data_string = "%5.1fK".printf(bytes / 1024.0);
    }
    else if (bytes < 104857600)  // Less than 100MB
    {
      data_string = "%5.1fM".printf(bytes / 1048576.0);
    }
    else  // Displays GB
    {
      data_string = "%5.1fG".printf(bytes / 1073741824.0);
    }
    return data_string;
  }
  
  public static string format_net_usage(uint64 down_bytes, uint64 up_bytes)
  {
    var down_rate = get_data_string((down_bytes - _current_down_bytes) / (POLL_INTERVAL / 1000)) + "/s";
    var up_rate = get_data_string((up_bytes - _current_up_bytes) / (POLL_INTERVAL / 1000)) + "/s";
    return "D: %s (%s) U: %s (%s)".printf
    (
      get_data_string(down_bytes), down_rate, get_data_string(up_bytes), up_rate
    );
  }
  
  public static void show_about()
  {
    Gtk.AboutDialog dialog = new Gtk.AboutDialog();
    dialog.program_name = "Net Usage Monitor";
    dialog.version = "Version 0.2";
    dialog.response.connect((response_id) => {dialog.destroy();});
    dialog.present();
    dialog.resize(80, 60);
  }

  public static void read_network_usage(out uint64 down_bytes, out uint64 up_bytes)
  {
    down_bytes = up_bytes = 0;
    const string NETSTAT_FILE = "/proc/net/netstat";
    var netstat = File.new_for_path(NETSTAT_FILE);
    try
    {
      var input_stream = new DataInputStream(netstat.read());
      string line;
      while ((line = input_stream.read_line(null)) != null)
      {
        if (Regex.match_simple("""IpExt: \d""", line))
        {
          string[] split_line = line.split(" ");
          split_line[7].scanf("%llu", out down_bytes);
          split_line[8].scanf("%llu", out up_bytes);
          return;
        }
      }
    }
    catch (Error e)
    {
      error("%s", e.message);
    }
  }
}
