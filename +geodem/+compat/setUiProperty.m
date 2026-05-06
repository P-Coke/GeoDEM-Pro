function setUiProperty(obj, propertyName, value)
%SETUIPROPERTY Set a UI property only when supported by the release.

try
    if isprop(obj, propertyName)
        obj.(propertyName) = value;
    end
catch
end
end
