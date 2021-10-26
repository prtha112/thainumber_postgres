CREATE OR REPLACE FUNCTION public.thai_number(
	input_number text,
	input_flag_digit boolean)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	numberInput 				TEXT := input_number;
	digitFlag					BOOLEAN := input_flag_digit;
	numberArray					TEXT[] := regexp_split_to_array(numberInput, ''); -- {2,3,1}
	thaiNumber   				TEXT[] := ARRAY['ศูนย์', 'หนึ่ง', 'สอง', 'สาม', 'สี่', 'ห้า', 'หก', 'เจ็ด', 'แปด', 'เก้า'];
	thaiUnit					TEXT[] := ARRAY['', 'สิบ', 'ร้อย', 'พัน', 'หมื่น', 'แสน', 'ล้าน'];
	
	unitPlain					TEXT := '';
	numberPlain					TEXT := '';
	resultPlain					TEXT := '';
	
	tmp_number					TEXT;
	box_state					INTEGER := 0;
	
	t 							INTEGER DEFAULT 0;
	j 							INTEGER DEFAULT 0;
	k							INTEGER DEFAULT 0;
BEGIN
	t := CHAR_LENGTH(numberInput);
	j := CHAR_LENGTH(numberInput);
	k := CHAR_LENGTH(numberInput);
	
	FOR i IN array_lower(numberArray, 1) .. array_upper(numberArray, 1)
   	LOOP
		-- some computations
        IF j > 7 THEN
            k := j - 7;
			unitPlain = thaiUnit[k+1];
        ELSE
            k := j;
			unitPlain = thaiUnit[k];
		END IF;
		
        IF numberArray[i] = '1' AND k = 1 AND j <= 7 AND tmp_number != '0' THEN
            numberPlain := 'เอ็ด';
			box_state := 1;
        ELSIF numberArray[i] = '1' AND j = 7 AND t > 7 AND tmp_number != '0' THEN
            numberPlain := 'เอ็ด';
			box_state := 2;
		ELSIF numberArray[i] = '1' AND j = 1 AND k = 1 AND t > 7 THEN
            numberPlain := 'หนึ่ง';
			box_state := 3;
		ELSIF numberArray[i] = '1' AND j = 2 AND k = 2 AND t < 7 THEN
            numberPlain := '';
			box_state := 4;
        ELSIF numberArray[i] = '1' AND k = 2 AND j = 2 THEN
            numberPlain := '';
			box_state := 5;
		ELSIF numberArray[i] = '1' AND k = 1 AND t > 7 AND j = 8 THEN
            numberPlain := '';
			box_state := 9;
        ELSIF numberArray[i] = '2' AND (k IN(1,2) AND j IN(2,8)) THEN
            numberPlain := 'ยี่';
			box_state := 6;
        ELSIF numberArray[i] = '0' AND digitFlag != TRUE THEN
            numberPlain := '';
            unitPlain := '';
			box_state := 7;
        ELSE
            numberPlain := thaiNumber[numberArray[i]::INTEGER + 1];
			box_state := 8;
		END IF;
		
		IF digitFlag = TRUE AND numberArray[i] = '0' AND j = 2 THEN
			unitPlain := '';
		END IF;
		
		IF j = 7 AND unitPlain NOT LIKE '%ล้าน%' THEN
			unitPlain := 'ล้าน' ;
		END IF;
		
        tmp_number = numberArray[i];
		
		resultPlain := resultPlain || COALESCE(numberPlain, '') || COALESCE(unitPlain, '');
		-- RAISE NOTICE 'Loop box = %, j = %, k = %, i = %, unit = %, number = %, %', box_state, j, k, i, unitPlain, numberPlain, numberArray[i];
		j := j - 1;
	END LOOP;
	IF resultPlain = '' THEN
		resultPlain := 'ศูนย์';
	END IF;
	RAISE NOTICE '% : %', numberInput, resultPlain;
	RETURN resultPlain;
END
$BODY$;

ALTER FUNCTION public.thai_number(text, boolean)
    OWNER TO postgres;
