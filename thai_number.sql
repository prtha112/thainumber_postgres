CREATE OR REPLACE FUNCTION public.thai_number(
	input_number numeric)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	numberInput 			NUMERIC(12,2) := input_number;
	numberFormat			TEXT[];
	
	resultNumber 			TEXT;
BEGIN
	IF numberInput IS NULL THEN
		RAISE EXCEPTION 'ไม่รับค่า Null.';
	ELSE
		numberFormat := string_to_array(numberInput::TEXT, '.');
	END IF;
	resultNumber := thai_number(numberFormat[1], false);
	IF CHAR_LENGTH(numberFormat[1]) > 14 THEN
		RAISE EXCEPTION 'จำนวนตัวเลขเกิน 14 หลัก (รับได้สูงสุดที่ 99999999999999)';
	END IF;
	IF array_length(numberFormat, 1) >= 1 THEN
		IF numberFormat[2]::INTEGER = 0 THEN
			resultNumber := resultNumber || 'บาทถ้วน'; 
		ELSE
			resultNumber := resultNumber || 'จุด' || thai_number(numberFormat[2], true) || 'สตางค์';
		END IF;
	END IF;
	-- RAISE NOTICE '% %', array_length(numberFormat, 1), resultNumber;
	RETURN resultNumber;
END
$BODY$;

ALTER FUNCTION public.thai_number(numeric)
    OWNER TO postgres;
