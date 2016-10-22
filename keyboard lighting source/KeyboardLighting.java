import java.lang.Process;
import java.util.Scanner;
import javax.swing.Timer;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

public class KeyboardLighting {
	static final int CHANGE_INTERVAL = 200;
	
	static final float BRIGHTEN_RATE = (float) 0.25;
	static final float DIM_RATE = (float) 1.25;
		
	static final float MIN_ACTIVITY_LEVEL = (float) 1.02 - BRIGHTEN_RATE;
	static transient float activity_level = (float) 0.0;
	
	public static void main(String[] arguments) {
		Thread brighten_thread = new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					Process keyboard_event_checker = Runtime.getRuntime().exec("evtest /dev/input/event8");
					Scanner scanner = new Scanner(keyboard_event_checker.getInputStream());
			
					while (scanner.hasNext()) {
						scanner.nextLine();
						activity_level += BRIGHTEN_RATE;
						if (activity_level >= 4.0)
							activity_level = (float) 3.9;
					}
				} catch (IOException exception) {
					exception.printStackTrace();
				}
			}
		});
		brighten_thread.start();
		
		Timer dim_timer = new Timer(CHANGE_INTERVAL, new ActionListener() {
			@Override
			public void actionPerformed(ActionEvent event) {
				try {
					FileOutputStream out = new FileOutputStream(new File("/sys/class/leds/asus::kbd_backlight/brightness"));
					String new_brightness = String.valueOf((byte) activity_level);
					out.write(new_brightness.getBytes());
					out.close();
				} catch (IOException exception) {
					exception.printStackTrace();
				}
				
				activity_level -= DIM_RATE;
				if (activity_level < MIN_ACTIVITY_LEVEL)
					activity_level = MIN_ACTIVITY_LEVEL;
			}
		});
		dim_timer.setRepeats(true);
		dim_timer.start();
	}
}
