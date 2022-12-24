unit streams;

interface

type
  ICloseable = interface(IInterface)['{884BFB20-3B01-419F-92EA-69719D38AE17}']
    procedure close;
  end;

  ISerializable = interface(IInterface)['{D9F9547C-CEA7-4C0F-8D93-7A1DA444C10F}']
  end;

  IFlushable = interface(IInterface)['{3A3AEEE4-BFE2-4B0A-85B8-4D17F6102298}']
    procedure flush;
  end;

implementation

end.
