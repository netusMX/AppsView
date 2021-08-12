public class AppsView.AppsViewWindow : Gtk.Window {

    private int monitor_number;
    private int monitor_width;
    private int monitor_height;
    private int monitor_x;
    private int monitor_y;
    private int panel_height;
    private bool expanded = true;
    public signal void app_launched ();

    public AppsViewWindow (Gtk.Application application) {
        Object (
            application: application,
            app_paintable: true,
            decorated: false,
            resizable: false,
            skip_pager_hint: true,
            skip_taskbar_hint: true,
            vexpand: true,
            hexpand: true
            // fullscreen: true
        );

        var apps_view = new AppsView();
        var style_context = get_style_context ();
        apps_view.set_window (this);
        add(apps_view);
        fullscreen();
        this.screen.size_changed.connect (update_apps_view_dimensions);
        this.screen.monitors_changed.connect (update_apps_view_dimensions);
        this.screen_changed.connect (update_visual);
        update_visual ();
        update_apps_view_dimensions();
    }

    public void closeApp() {
        close();
    }

    private void update_apps_view_dimensions () {

        monitor_number = screen.get_primary_monitor ();
        Gdk.Rectangle monitor_dimensions;

        monitor_dimensions = get_display ().get_primary_monitor ().get_geometry ();
        monitor_width = monitor_dimensions.width;
        monitor_height = monitor_dimensions.height;

        this.set_size_request (monitor_width, monitor_height);

        monitor_x = monitor_dimensions.x;
        monitor_y = monitor_dimensions.y;
    }

    private void update_visual () {
        var visual = this.screen.get_rgba_visual ();

        if (visual == null) {
            warning ("Compositing not available, things will Look Bad (TM)");
        } else {
            this.set_visual (visual);
        }
    }
}
