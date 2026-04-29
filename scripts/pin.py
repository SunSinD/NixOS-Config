#!/usr/bin/env python3
"""Pin a screenshot to the screen as a floating, draggable window."""
import gi, sys, os
os.environ.setdefault("GDK_BACKEND", "wayland,x11")
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GdkPixbuf

class PinWindow(Gtk.Window):
    def __init__(self, path):
        super().__init__()
        self.set_title("pin")
        self.set_wmclass("pin", "pin")
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)

        pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)
        image = Gtk.Image.new_from_pixbuf(pixbuf)

        event_box = Gtk.EventBox()
        event_box.add(image)
        event_box.connect("button-press-event", self.on_press)
        self.add(event_box)

        self.connect("key-press-event", self.on_key)

        css = Gtk.CssProvider()
        css.load_from_data(b"""
            window { border: 1px solid rgba(180,180,180,0.4); }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        self.show_all()

    def on_press(self, widget, event):
        if event.button == 1:
            self.begin_move_drag(
                int(event.button),
                int(event.x_root),
                int(event.y_root),
                event.time,
            )
        elif event.button == 3:
            Gtk.main_quit()

    def on_key(self, widget, event):
        if event.keyval in (Gdk.KEY_Escape, Gdk.KEY_q):
            Gtk.main_quit()
            return True
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    try:
        PinWindow(sys.argv[1])
        Gtk.main()
    except Exception as e:
        print(f"Pin error: {e}", file=sys.stderr)
        sys.exit(1)
