using Toybox.WatchUi as Ui;

class HRIndexView extends Ui.SimpleDataField {

	hidden var _SHR;
	hidden var _avgTime;
	hidden var _arraySHR;
	hidden var _arrayTime;
	hidden var _first;
	hidden var _last;
	hidden var _sumSHR;
	hidden var _sumTime;
	hidden var _lastTime;
	hidden var _lastHRI;
    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        _SHR = Application.getApp().getProperty("shr");
        _avgTime = Application.getApp().getProperty("avgTime");
        label = "HR Index" +" " + _SHR.format("%.0f") +"/"+ _avgTime.format("%.0f");
        _arraySHR = new [0];
        _arrayTime = new [0];
	 	_first = 0;
		_last = 0;
		_sumSHR = 0.0f;
		_sumTime = 0.0f;
		_lastTime = 0.0f;
		_lastHRI = -1.0f;		
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    function compute(info) { 
        // See Activity.Info in the documentation for available information.
        if(info has :currentHeartRate && info has :currentSpeed){
            if(info.currentHeartRate != null && info.currentSpeed != null && 
            info.currentHeartRate > _SHR && info.currentSpeed > 0.3f){
            	var time = info.elapsedTime;
				if (time != null) {
					time /= 1000;
				} else {
					time = 0.0;
				}
				var hri = ((info.currentHeartRate - _SHR) / info.currentSpeed);
				if (_lastHRI < 0.0 || _lastTime <= 0.0){
					_lastHRI =  hri;
				}
				if (_lastTime < time){
					
 					var dt = time-_lastTime; 
					_arraySHR.add(hri*dt);
					_arrayTime.add(dt);
					_sumSHR += hri*dt;
					_sumTime += dt; 
					while (_sumTime > _avgTime && _arraySHR.size() > 1){
						_sumSHR -= _arraySHR[0];
						_arraySHR = _arraySHR.slice(1, 0);
						_sumTime -= _arrayTime[0];
						_arrayTime = _arrayTime.slice(1, 0);
					}
					_lastTime =  time;
					_lastHRI = _sumSHR / _sumTime;
				}
								
               	return  _lastHRI.format("%.0f");                
            } 
        }
        return "-";
    }

}