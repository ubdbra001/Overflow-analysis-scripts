function func_warning(message)

border = repmat('*',1, length(message)+4);
fprintf('\n\n%s\n* %s *\n%s\n\n', border, message, border)