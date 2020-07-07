function [mousePos, mousePress] = getMousePosition()

% click the mouse
[x,y,buttons] = GetMouse;

while any(buttons) % if already down, wait for release
    [x,y,buttons] = GetMouse;
end

while ~any(buttons) % wait for press
    [x,y,buttons] = GetMouse;
    
%     disp(num2str(x))
%     WaitSecs(0.1);
end

while any(buttons) % wait for release
    [x,y,buttons] = GetMouse;
    
    disp(num2str(x))
    WaitSecs(0.1);
    disp(num2str(buttons))
end


end