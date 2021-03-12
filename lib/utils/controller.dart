

class Controller<STATUS, EVENT, RESULT> {
  RESULT Function(EVENT) onEvent;

  RESULT send(EVENT event) => onEvent?.call(event);


  STATUS get status => onStatus?.call();

  STATUS Function() onStatus;

}