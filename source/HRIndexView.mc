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
using Toybox.FitContributor as Fit;

class HRIndexView extends Ui.SimpleDataField {

    hidden var _SHR;
    hidden var _avgTime;
    hidden var _avgDist;
    hidden var _elevMode;

    hidden var _arrayTime;
    hidden var _arraySpeed;
    hidden var _arrayDist;
    hidden var _arrayAlt;
    hidden var _arrayGrad;
    hidden var _sumSpeed;
    hidden var _sumTime;
    hidden var _lapHRIndexDt;
    hidden var _lapHRIndex;
    hidden var _sumHRIndex;
    hidden var _sumHRIndexDt;
    hidden var _lastTime;
    hidden var _lastHRI;
    hidden var _lastGrad;
    hidden var _gradFact;
    hidden var _minettiZero;
    hidden var _minettiMinX;
    hidden var _minettiMinA;
    hidden var _minettiMinB;
    hidden var _minettiMaxX;
    hidden var _minettiMaxA;
    hidden var _minettiMaxB;
    hidden var _fitHri;
    hidden var _fitHRIndexAvg;
    hidden var _fitHRIndexLap;
    hidden var _fitGrad;

    function initialize() {
        SimpleDataField.initialize();
 
        _SHR = getFloatProperty("shr", 60.0f);
        _avgTime = getFloatProperty("avgTime", 20.0f);
        _avgDist = getFloatProperty("avgDist", 75.0f);
        _elevMode = Application.getApp().getProperty("elevMode");
        _gradFact = getFloatProperty("gradFact", 0.8f);
 
        var e = "";
        if (_elevMode == 1){
            e = "/C"; //+ _avgDist.format("%.0f");
        }
        else if (_elevMode == 2){
            e = "/M"; // + _avgDist.format("%.0f");       
        }
 
        label = "HR Index" +" " + _SHR.format("%.0f") +"/"+ _avgTime.format("%.0f") + e;
 
        _arrayTime = new [0];
        _arraySpeed = new [0];
        _arrayDist = new [0];
        _arrayAlt = new [0];
        _arrayGrad = new [0];
        _lapHRIndexDt = 0.0f;
        _lapHRIndex = 0.0f;
        _sumSpeed = 0.0f;
        _sumTime = 0.0f;
        _lastTime = 0.0f;
        _lastGrad = 0.0f;
        _sumHRIndex = 0.0f;
        _sumHRIndexDt = 0.0f;
        _lastHRI = -1.0f;        
        _minettiZero = minetti(0.0);
        _minettiMinX = -0.45f;
        _minettiMinA = minettiDiv(_minettiMinX);
        _minettiMinB = minetti(_minettiMinX);
        _minettiMaxX = 0.45f;
        _minettiMaxA = minettiDiv(_minettiMaxX);
        _minettiMaxB = minetti(_minettiMaxX);
        _fitHri = createField("hrIndex", 0, Fit.DATA_TYPE_FLOAT, { :mesgType=>Fit.MESG_TYPE_RECORD });
        _fitHRIndexAvg = createField("runHRIndexAvg", 1, Fit.DATA_TYPE_FLOAT, { :mesgType=>Fit.MESG_TYPE_SESSION, :units=>"w" });
        _fitHRIndexLap = createField("runHRIndexLap", 2, Fit.DATA_TYPE_FLOAT, { :mesgType=>Fit.MESG_TYPE_LAP, :units=>"w" });
        _fitGrad = createField("runHRIndexGradient", 3, Fit.DATA_TYPE_FLOAT, { :mesgType=>Fit.MESG_TYPE_RECORD , :units=>"%"});
        _fitHRIndexAvg.setData(0.0f);
        _fitHRIndexLap.setData(0.0f);
    }

    function compute(info) { 
        if(info has :currentHeartRate && info has :currentSpeed){
            if(info.currentHeartRate != null && info.currentSpeed != null && 
               info.currentHeartRate > _SHR && info.currentSpeed > 0.3f){
                
                var v = info.currentSpeed;
                var hr = info.currentHeartRate - _SHR; 
                var time = info.timerTime;
                if (time != null) {
                    time /= 1000;
                } else {
                    time = 0.0;
                }
                
                if (_lastHRI < 0.0 || _lastTime <= 0.0){
                    _lastHRI =  hr / v;
                }
                
                var act = Toybox.Activity.getActivityInfo();
                var altitude = null;
                var dist = null;                
                if (info has :elapsedDistance && act has :altitude ){
                    if (info.elapsedDistance != null && act.altitude != null){
                        altitude = act.altitude;
                        dist = info.elapsedDistance;
                    }
                }
                if (altitude != null && _arrayDist.size() == 0){
                    _arrayDist.add(dist);
                    _arrayAlt.add(altitude);
                }
                
                if (_lastTime < time){
                    
                    var dt = time-_lastTime; 
                    _sumSpeed += v*dt;
                    _arraySpeed.add(v*dt);
                    _sumTime += dt;
                    _arrayTime.add(dt);
                    while (_sumTime > _avgTime && _arrayTime.size() > 1){                       
                        _sumTime -= _arrayTime[0];
                        _arrayTime = _arrayTime.slice(1, _arrayTime.size());
                        _sumSpeed -= _arraySpeed[0];
                        _arraySpeed = _arraySpeed.slice(1, _arraySpeed.size());
                    }
                    
                    if (altitude != null){
                        _arrayDist.add(dist);
                        _arrayAlt.add(altitude);
                    }
                    while (_arrayDist.size() > 2 && _arrayDist[_arrayDist.size()-1] -_arrayDist[1] > _avgDist){                        
                        _arrayDist = _arrayDist.slice(1, _arrayDist.size());
                        _arrayAlt = _arrayAlt.slice(1, _arrayAlt.size());
                    }
                    var elev = 0.0;
                    if (_arrayDist.size() > 1){
                        dist = _arrayDist[_arrayDist.size()-1] - _arrayDist[0];
                        elev = _arrayAlt[_arrayAlt.size()-1] - _arrayAlt[0];
                        _arrayGrad.add(dist > 1.0 && time > _avgTime ? elev/dist:0.0);
                        while (_arrayGrad.size() > _arrayDist.size()){
                            _arrayGrad = _arrayGrad.slice(1, _arrayGrad.size());
                        }
                    }        
                    if (_arrayGrad.size() > 0){
                        _lastGrad = 0.0;
                        var sum = 0.0;
                        var f = 1.0;
                        for (var i=0;i<_arrayGrad.size();i++){
                            _lastGrad += _arrayGrad[_arrayGrad.size()-1-i]*f;
                            sum += f;
                            f *= _gradFact;
                        }
                        _lastGrad /= sum;
                    }
                                        
                    var f = 1.0;
                    if (_elevMode > 0){
                        if (_elevMode == 2){
                            f = minettiBounded(_lastGrad)/_minettiZero;
                        }
                        else if (elev > 0){
                            f = 1.0 + 6.0*_lastGrad;
                        }    
                    }
                                        
                    _lastTime =  time;
                    _lastHRI = hr / (_sumSpeed / _sumTime) / f;
                    _sumHRIndex += _lastHRI*dt;
                    _sumHRIndexDt += dt;
                    _lapHRIndex += _lastHRI*dt;
                    _lapHRIndexDt += dt;
                    _fitHRIndexAvg.setData((_sumHRIndex/_sumHRIndexDt).toFloat());
                    _fitHRIndexLap.setData((_lapHRIndex/_lapHRIndexDt).toFloat());
                }
                _fitHri.setData(_lastHRI);                
                _fitGrad.setData(_lastGrad*100);
                                 
                   return  _lastHRI.format("%.0f");                
            } 
        }
        return "-";
    }
    
    function onTimerLap() {
        _lapHRIndexDt = 0.0f;
        _lapHRIndex = 0.0f;
    }
       
    function minettiBounded(g){
        if (g <= _minettiMinX){
            return _minettiMinA * (g - _minettiMinX) + _minettiMinB;
        }
        if (_minettiMaxX <= g){
            return _minettiMaxA * (g - _minettiMaxX) + _minettiMaxB;
        }
        return minetti(g);
    }
    
    function minetti(g){
        return 106.7731478*g*g*g*g*g - 47.23550515*g*g*g*g - 33.40634794*g*g*g + 49.35038999*g*g + 19.12318478*g + 3.389064903;
        // return 155.4*g*g*g*g*g - 30.4*g*g*g*g - 43.3*g*g*g + 46.3*g*g + 19.5*g + 3.6;
    }
    
    function minettiDiv(g){
        return 106.7731478*g*g*g*g*5.0 - 47.23550515*g*g*g*4.0 - 33.40634794*g*g*3.0 + 49.35038999*g*2.0 + 19.12318478;
    }
    
    // https://forums.garmin.com/forum/developers/connect-iq/122198-
    function getFloatProperty(key, initial) {
        var value = Application.getApp().getProperty(key);
        if (value != null) {

            if (value instanceof Lang.String ||
                     value instanceof Lang.Double ||
                     value instanceof Lang.Long ||
                     value instanceof Lang.Number||
                     value instanceof Lang.Float) {
                return value;
            }
            else if (value instanceof Lang.Boolean) {
                return value ? 1.0f : 0.0f;
            }
        }

        return initial;
    }
}
