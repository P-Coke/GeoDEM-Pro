function setUiCallback(obj, propertyName, value)
%SETUICALLBACK Set a UI callback only when the running release supports it.

try
    obj.(propertyName) = value;
catch
end
end
