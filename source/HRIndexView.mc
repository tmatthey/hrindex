/*
 * ***** BEGIN LICENSE BLOCK *****
 * Version: MIT
 *
 * Copyright (c) 2017 Thierry Matthey
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * ***** END LICENSE BLOCK *****
 */


using Toybox.WatchUi as Ui;

class HRIndexView extends Ui.SimpleDataField {

    hidden var _SHR;
    hidden var _avgTime;
    hidden var _avgDist;
    hidden var _elevMode;

    hidden var _arraySHR;
    hidden var _arrayTime;
    hidden var _arrayDist;
    hidden var _arrayAscent;
    hidden var _arrayDescent;
    hidden var _sumSHR;
    hidden var _sumTime;
    hidden var _lastTime;
    hidden var _lastHRI;
    hidden var _minettiZero;

    function initialize() {
        SimpleDataField.initialize();
 
        _SHR = Application.getApp().getProperty("shr");
        _avgTime = Application.getApp().getProperty("avgTime");
        _avgDist = Application.getApp().getProperty("avgDist");
        _elevMode = Application.getApp().getProperty("elevMode");
 
        var e = "";
        if (_elevMode == 1){
            e = "/C"; //+ _avgDist.format("%.0f");
        }
        else if (_elevMode == 2){
            e = "/M"; // + _avgDist.format("%.0f");       
        }
 
        label = "HR Index" +" " + _SHR.format("%.0f") +"/"+ _avgTime.format("%.0f") + e;
 
        _arraySHR = new [0];
        _arrayTime = new [0];
        _arrayDist = [0.0];
        _arrayAscent = [0.0];
        _arrayDescent = [0.0];
        _sumSHR = 0.0f;
        _sumTime = 0.0f;
        _lastTime = 0.0f;
        _lastHRI = -1.0f;		
        _minettiZero = minetti(0.0);
    }

    function compute(info) { 
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
                    
                    if (info has :elapsedDistance && info has :totalAscent && info has :totalDescent ){
                        if (info.elapsedDistance != null && info.totalAscent != null&& info.totalDescent != null){
                            _arrayDist.add(info.elapsedDistance);
                            _arrayAscent.add(info.totalAscent);
                            _arrayDescent.add(info.totalDescent);
                        }
                    }
                    
                    var dt = time-_lastTime; 
                    _arraySHR.add(hri*dt);
                    _arrayTime.add(dt);
                    _sumSHR += hri*dt;
                    _sumTime += dt;
                    
                    while (_sumTime > _avgTime && _arraySHR.size() > 1){
                        
                        _sumSHR -= _arraySHR[0];
                        _arraySHR = _arraySHR.slice(1, _arraySHR.size());
                        _sumTime -= _arrayTime[0];
                        _arrayTime = _arrayTime.slice(1, _arrayTime.size());
                    }
                    
                    while (_arrayDist.size() > 2 && _arrayDist[_arrayDist.size()-1] -_arrayDist[1] > _avgDist){						
                        _arrayDist = _arrayDist.slice(1, _arrayDist.size());
                        _arrayAscent = _arrayAscent.slice(1, _arrayAscent.size());
                        _arrayDescent = _arrayDescent.slice(1, _arrayDescent.size());
                    }

                    var f = 1.0;
                    if (_elevMode > 0){
                        if (_arrayDist.size() > 1){
                            var dist = _arrayDist[_arrayDist.size()-1] - _arrayDist[0];
                            var elev = _arrayAscent[_arrayAscent.size()-1] - _arrayAscent[0] - (_arrayDescent[_arrayDescent.size()-1] - _arrayDescent[0]);
                            if (dist > 1.0){
                                if (_elevMode == 2){
                                    if (dist > 0.75 * _avgDist){
                                        f = minetti(elev/dist)/_minettiZero;
                                    }		
                                }
                                else if (elev > 0){
                                    f = (dist + 6.0 * elev)/dist;
                                }							
                            }
                        }
                    }
										
                    _lastTime =  time;
                    _lastHRI = _sumSHR / _sumTime / f;
                }
								
               	return  _lastHRI.format("%.0f");                
            } 
        }
        return "-";
    }
    
    function minetti(g){
        return 106.7731478*g*g*g*g*g - 47.23550515*g*g*g*g - 33.40634794*g*g*g + 49.35038999*g*g + 19.12318478*g + 3.389064903;
        // return 155.4*g*g*g*g*g - 30.4*g*g*g*g - 43.3*g*g*g + 46.3*g*g + 19.5*g + 3.6;
    }
}
