package utils
{
	public class TimeUtils
	{		
		static public function ConvertSecondsToString(totalSeconds:Number) : String
		{
			var minutes : Number = Math.floor(totalSeconds / 60);
			var seconds : Number = Math.floor(totalSeconds % 60);
			
			var secondsStr : String = seconds < 10? "0"+seconds.toString() : seconds.toString();
			
			return minutes.toString() + ":" + secondsStr;
		}
		
		static public function ConvertSecondsToStringWithHours(totalSeconds:Number) : String
		{
			var hours   : Number = Math.floor(totalSeconds / 3600);
			var minutes : Number = Math.floor((totalSeconds / 60) - (hours * 60));
			var seconds : Number = Math.floor(totalSeconds % 60);
			
			var minutesStr : String = minutes < 10? "0"+minutes.toString() : minutes.toString();
			var secondsStr : String = seconds < 10? "0"+seconds.toString() : seconds.toString();
						
			return hours.toString() + ":" + minutesStr + ":" + secondsStr;
		}
		
		static public function ConvertSecondsToStringVerbose(totalSeconds:Number) : String
		{
			if (totalSeconds < 0)
				return "";
			
			var days : Number = Math.floor(totalSeconds / (3600 * 24));
			
			var remainderHours : Number = totalSeconds % (3600 * 24);
			var hours   : Number = Math.floor(remainderHours / 3600);
			
			var remainderMinutes : Number = remainderHours % 3600;
			var minutes : Number = Math.floor(remainderMinutes / 60);
			
			var seconds : Number = Math.floor(remainderMinutes % 60);
			
			var daysStr	   : String = days.toString();
			var hoursStr   : String = hours   < 10? "0"+hours.toString()   : hours.toString();
			var minutesStr : String = minutes < 10? "0"+minutes.toString() : minutes.toString();
			var secondsStr : String = seconds < 10? "0"+seconds.toString() : seconds.toString();
			
			if (days != 0)
				daysStr = daysStr + (days == 1? " dia " : " dias ");
			else
				daysStr = "";
			
			if (hours != 0 || days != 0)
				hoursStr = hoursStr + (hours == 1? " hora " : " horas ");
			else
				hoursStr = "";
			
			minutesStr = minutesStr + (minutes == 1? " min " : " mins ");
			secondsStr = secondsStr + (seconds == 1? " seg " : " segs ");
			
			return daysStr + hoursStr + minutesStr + secondsStr;
		}
	}
}