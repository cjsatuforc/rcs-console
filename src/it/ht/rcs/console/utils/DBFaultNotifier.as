package it.ht.rcs.console.utils
{
  
  import it.ht.rcs.console.IFaultNotifier;
  import it.ht.rcs.console.accounting.controller.SessionManager;
  import it.ht.rcs.console.push.PushController;
  
  import mx.managers.CursorManager;
  import mx.resources.ResourceManager;
  import mx.rpc.events.FaultEvent;
  
  public class DBFaultNotifier implements IFaultNotifier
  {
    public function DBFaultNotifier()
    {
    }
    
    public function fault(e:FaultEvent):void
    {
      var message:String = "ERROR";
      
      /* remove the busy cursor */
      CursorManager.removeBusyCursor();
      
      /* avoid multiple messages, by checking if the currentSession is valid */
      if (Console.currentSession == null)
        return;
      
      if (PushController.instance.status == PushController.CONNECTING) {
        AlertPopUp.show("Reconnecting...");
        return;
      }
      
      /* errors from the websocket interface */
      if (e.type == 'ws') {
        //AlertPopUp.show(ResourceManager.getInstance().getString('localized_db_messages', 'WS_ERROR'), ResourceManager.getInstance().getString('localized_main', 'ERROR_CODE', [e.statusCode.toString()]));
        SessionManager.instance.forceLogout();
        return; 
      }
      
      /* http code 403 means our session is not valid */
      if (e.statusCode == 403) {
        AlertPopUp.show(ResourceManager.getInstance().getString('localized_db_messages', 'INVALID_SESSION'), ResourceManager.getInstance().getString('localized_main', 'ERROR_CODE', [e.statusCode.toString()]));
        SessionManager.instance.forceLogout();
        return; 
      }
      
      /* server error (cannot connect) */
      if (e.statusCode == 0) {
        AlertPopUp.show(ResourceManager.getInstance().getString('localized_db_messages', 'SERVER_ERROR'), ResourceManager.getInstance().getString('localized_main', 'ERROR'));
        //SessionManager.instance.forceLogout();
        return;
      }
      
      /* decode the message from the server */
      var decoded:*;
      try {
        decoded = JSON.parse(e.fault.content as String);
      } catch (je:*) {
        decoded = e.fault.content as String;
        AlertPopUp.show(decoded, ResourceManager.getInstance().getString('localized_main', 'ERROR_CODE', [e.statusCode.toString()]));
        return;
      }
      
      /* guess which error it is */
      if (decoded is Array)
        message = decoded[0];
      else if (decoded is String)
        message = decoded;
      else
        message = decoded.toString();
      
      var localized_error:String = ResourceManager.getInstance().getString('localized_db_messages', message);
      
      if (localized_error == null)
        localized_error = message;
      
      AlertPopUp.show(localized_error, ResourceManager.getInstance().getString('localized_main', 'ERROR'));
    }
  }
}
