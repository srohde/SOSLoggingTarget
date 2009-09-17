/*
  Copyright (c) 2008-2009, Sönke Rohde
  All rights reserved.

  Redistribution and use in source and binary forms, with or without 
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
  
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution.
  
  * Neither the name of Adobe Systems Incorporated nor the names of its 
    contributors may be used to endorse or promote products derived from 
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.soenkerohde.logging
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.XMLSocket;
	
	import mx.core.mx_internal;
	import mx.logging.ILogger;
	import mx.logging.LogEvent;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.LineFormattedTarget;

	use namespace mx_internal;

	public class SOSLoggingTarget extends LineFormattedTarget
	{
		
		private var socket:XMLSocket;
		private var history:Array;
		
		[Inspectable(category="General", defaultValue="localhost")]
		public var server:String = "localhost";
		
		public function SOSLoggingTarget()
		{
			socket = new XMLSocket();
			history = new Array();
			includeCategory = true;
			includeTime = true;
			includeLevel = true;
		}
		
		override public function logEvent(event:LogEvent):void
	    {
	    	var log:Object = {message:event.message};
	    	
	        if (includeDate || includeTime)
	        {
	            var d:Date = new Date();
	            if (includeDate)
	            {
	                log.date = Number(d.getMonth() + 1).toString() + "/" +
	                       d.getDate().toString() + "/" + 
	                       d.getFullYear();
	            }   
	            if (includeTime)
	            {
	                log.time = padTime(d.getHours()) + ":" +
	                        padTime(d.getMinutes()) + ":" +
	                        padTime(d.getSeconds()) + "." +
	                        padTime(d.getMilliseconds(), true);
	            }
	        }
	        
	        if(includeLevel)
	        {
	            log.level = event.level;
	        }
	
	        log.category = includeCategory ? ILogger(event.target).category : "";
	
	        if(socket.connected)
	        {
	        	send(log);
	        }
	        else
	        {
	        	if(!socket.hasEventListener("connect"))
                {
                    socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
                    socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
                    socket.addEventListener(Event.CONNECT, onConnect);
                }
                socket.connect(server, 4444);
                history.push(log);
	        }
	    }
	    
	    private function onIOError(e:IOErrorEvent):void
	    {
	    	trace("XMLSocket IOError");
	    }
	    
	    private function onSecurityError(e:SecurityErrorEvent):void
	    {
	    	trace("XMLSocket SecurityError");
	    }
	    
	    private function onConnect(e:Event):void
        {
            for each(var log:Object in history)
            {
                send(log);
            }
        }
        
        private function send(o:Object):void
        {
			var msg:String = o.message;
			var lines:Array = msg.split ("\n");
			var commandType:String= lines.length == 1 ? "showMessage" : "showFoldMessage";
			var key:String = getTypeByLogLevel(o.level);
			var xmlMessage:XML = <{commandType} key={key} />;
			
			if(lines.length > 1)
			{
				// set title with first line
				xmlMessage.title = lines[0];
				
				// remove title from message
				xmlMessage.message = msg.substr(msg.indexOf("\n") + 1, msg.length);
				
				if(o.date == null)
					xmlMessage.data = o.data;
				if(o.time == null)
					xmlMessage.time = o.time;
				if(o.category == null)
					xmlMessage.category = o.category;

			}
			else
			{
				var prefix:String = "";
				if(o.date != null)
					prefix += o.date + fieldSeparator;
				if(o.time != null)
					prefix += o.time + fieldSeparator;
				if(o.category != null)
					prefix += o.category + fieldSeparator;
					
				xmlMessage.appendChild(prefix + msg);
			}
			
			socket.send('!SOS'+xmlMessage.toXMLString()+'\n');
        }
        
        private function getTypeByLogLevel(level:int):String
        {
            switch(level)
            {
                case LogEventLevel.DEBUG :
                     return "DEBUG";
                case LogEventLevel.INFO :
                     return "INFO";
                case LogEventLevel.WARN :
                     return "WARN";
                case LogEventLevel.ERROR :
                     return "ERROR";
                case LogEventLevel.FATAL :
                     return "FATAL";
                default:
                    return "INFO";
            }
        }
        
        private function padTime(num:Number, millis:Boolean = false):String
	    {
	        if(millis)
	        {
	            if (num < 10)
	                return "00" + num.toString();
	            else if (num < 100)
	                return "0" + num.toString();
	            else 
	                return num.toString();
	        }
	        else
	        {
	            return num > 9 ? num.toString() : "0" + num.toString();
	        }
	    }
		
		override mx_internal function internalLog(message:String):void
	    {
	    }
		
	}
}