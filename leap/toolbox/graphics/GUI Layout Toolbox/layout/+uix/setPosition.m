function setPosition( o, p, u )
%setPosition  Set position of graphics object
%
%  setPosition(o,p,u) sets the position of a graphics object o to value p
%  with units u.
%
%  In contrast to setting the Position property directly, this function
%  honors the ActivePositionProperty of axes.

%  Copyright 2009-2016 The MathWorks, Inc.
%  $Revision: 1435 $ $Date: 2016-11-17 17:50:34 +0000 (Thu, 17 Nov 2016) $

o.Units = u;
if isa( o, 'matlab.graphics.axis.Axes' )
    switch o.ActivePositionProperty
        case 'position'
            o.Position = p;
        case 'outerposition'
            o.OuterPosition = p;
        otherwise
            error( 'uix:InvalidState', ...
                'Unknown value ''%s'' for property ''ActivePositionProperty'' of %s.', ...
                o.ActivePositionProperty, class( o ) )
    end
else
    o.Position = p;
end

end % setPosition