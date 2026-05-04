AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Resource.Name then
        return
    end

    print(('[%s] server started'):format(Resource.Name))
end)
