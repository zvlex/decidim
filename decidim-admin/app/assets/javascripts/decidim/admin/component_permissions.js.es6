// = require ./subform_toggler.component

// Este componente se encargaba de ocultar los setting de un AuthenticationHandler cuando era seleccionado.
// Estaba pensado para cuando era un select en vez de checkboxes. Hay que adaptarlo, crear o otro, o ver si
// tienen alguno que podamos reutilizar
((exports) => {
  const { SubformTogglerComponent } = exports.DecidimAdmin;

  const subformToggler = new SubformTogglerComponent({
    controllerSelect: $("select[name$=\\[authorization_handler_name\\]]"),
    subformWrapperClass: "authorization-handler",
    globalWrapperSelector: "fieldset"
  });

  subformToggler.run();
})(window);
