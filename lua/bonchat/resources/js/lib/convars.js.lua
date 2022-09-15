return [[(function() {
  if (window.convars) return;

  window.convars = {
    _convars: {},
    _callbacks: {},
    getString: function(name) {
      return this._convars[name];
    },
    getInt: function(name) {
      return parseInt(this._convars[name]);
    },
    getFloat: function(name) {
      return parseFloat(this._convars[name]);
    },
    getBool: function(name) {
      var val = parseInt(this._convars[name]);
      return !isNaN(val) && val != 0;
    },
    addConVarCallback: function(name, fn, identifier) {
      this.removeConVarCallback(name, identifier); // remove it incase a callback with the same identifier already exists
      if (!this._callbacks[name]) this._callbacks[name] = [];
      var obj = { fn };
      if (typeof identifier === "string") obj.identifier = identifier;
      this._callbacks[name].push(obj);
    },
    removeConVarCallback: function(name, identifier) {
      if (!this._callbacks[name] || typeof identifier !== "string") return;
      var callbacks = this._callbacks[name].filter(function(obj) { return obj.identifier !== identifier });
      if (callbacks.length)
        this._callbacks[name] = callbacks;
      else
        delete this._callbacks[name];
    },
    updateConVar: function(name, val) {
      if (val != null) {
        this._convars[name] = val.toString();
        var callbacks = this._callbacks[name];
        if (callbacks) {
          for (var i = 0; i < callbacks.length; i++) {
            callbacks[i].fn();
          }
        }
      } else {
        delete this._convars[name];
      }
    }
  };
})();

/* define GLua convar methods
POSTLUA:
  function self:AddJSConVar(name)
    self:UpdateJSConVar(name)
    BonChat.AddConVarCallback(name, function(name, _, val) self:UpdateJSConVar(name, val) end, self)
  end
  function self:UpdateJSConVar(name, val)
    self:CallJSParams("convars.updateConVar('%s', '%s')", string.JavascriptSafe(name), string.JavascriptSafe(val or cvars.String(name)))
  end
:ENDLUA
*/]]