package mindscriptact.mvcExpressLogger {
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Window;

import mvcexpress.core.namespace.pureLegsCore;

/**
 * Class to control logger view.
 * Implements function chaining.
 */
public class LoggerViewManager {

	private const logWindow:Mvce_Window = new Mvce_Window();

	public function LoggerViewManager() {
	}

	pureLegsCore function getLoggerView():Mvce_Window {
		return logWindow;
	}

	public function moveTo(x:int, y:int):LoggerViewManager {
		logWindow.x = x;
		logWindow.y = y;
		return this;
	}
}
}
