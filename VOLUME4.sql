EXECUTE BLOCK RETURNS (
  id_pedido INTEGER,
  clicodigo INTEGER,
  gclcodigo INTEGER,
  chave VARCHAR(50),
  qtd INTEGER,
  procodigo VARCHAR(50)
) AS
DECLARE VARIABLE v_id_pedido INTEGER;
DECLARE VARIABLE v_clicodigo INTEGER;
DECLARE VARIABLE v_gclcodigo INTEGER;
DECLARE VARIABLE v_chave VARCHAR(50);
DECLARE VARIABLE v_qtd INTEGER;
DECLARE VARIABLE v_procodigo VARCHAR(50);
BEGIN
  -- PART 1: Generate and iterate over the main results
  FOR
    WITH CLI AS (
      SELECT DISTINCT 
        C.CLICODIGO,
        CLINOMEFANT,
        ENDCODIGO,
        GCLCODIGO
      FROM CLIEN C
      INNER JOIN (
        SELECT 
          CLICODIGO,
          E.ZOCODIGO,
          ENDCODIGO 
        FROM ENDCLI E
        INNER JOIN (
          SELECT ZOCODIGO 
          FROM ZONA 
          WHERE ZOCODIGO IN (20)
        ) Z ON E.ZOCODIGO = Z.ZOCODIGO 
        WHERE ENDFAT = 'S'
      ) A ON C.CLICODIGO = A.CLICODIGO 
      WHERE CLICLIENTE = 'S'
    ),
    FIS AS (
      SELECT FISCODIGO 
      FROM TBFIS 
      WHERE FISTPNATOP IN ('V', 'R', 'SR')
    ),
    PED AS (
      SELECT 
        ID_PEDIDO,
        PEDDTEMIS,
        P.CLICODIGO,
        GCLCODIGO,
        CLINOMEFANT
      FROM PEDID P
      INNER JOIN CLI C ON P.CLICODIGO = C.CLICODIGO AND P.ENDCODIGO = C.ENDCODIGO
      WHERE PEDDTEMIS BETWEEN DATEADD(-90 DAY TO CURRENT_DATE) AND 'YESTERDAY' 
      AND PEDSITPED <> 'C'
    ),
    PROD_LEN AS (
      SELECT 
        PROCODIGO,
        IIF(PROCODIGO2 IS NULL, PROCODIGO, PROCODIGO2) CHAVE 
      FROM PRODU 
      WHERE MARCODIGO IN (57, 24)
    )
    SELECT 
      PD.ID_PEDIDO,
      CLICODIGO,
      GCLCODIGO,
      CHAVE,
      SUM(PDPQTDADE) AS QTD
    FROM PDPRD PD
    INNER JOIN PED P ON PD.ID_PEDIDO = P.ID_PEDIDO
    INNER JOIN FIS F ON PD.FISCODIGO = F.FISCODIGO
    INNER JOIN PROD_LEN PR ON PD.PROCODIGO = PR.PROCODIGO
    GROUP BY 1, 2, 3, 4
  INTO :v_id_pedido, :v_clicodigo, :v_gclcodigo, :v_chave, :v_qtd
  DO
  BEGIN
    -- Check for corresponding PROCODIGO
    v_procodigo = NULL;
    FOR
      SELECT FIRST 1 PD.PROCODIGO
      FROM PDPRD PD
      INNER JOIN PRODU PR ON PD.PROCODIGO = PR.PROCODIGO
      WHERE PD.ID_PEDIDO = :v_id_pedido
        AND PR.PROTIPO = 'T'
      ORDER BY PD.ID_PEDIDO, PD.PROCODIGO
    INTO :v_procodigo
    DO
    BEGIN
      -- If PROCODIGO is found, exit the loop
      IF (:v_procodigo IS NOT NULL) THEN
      BEGIN
        LEAVE;
      END
    END

    -- Emit combined results
    id_pedido = :v_id_pedido;
    clicodigo = :v_clicodigo;
    gclcodigo = :v_gclcodigo;
    chave = :v_chave;
    qtd = :v_qtd;
    procodigo = :v_procodigo;
    SUSPEND;
  END
END;
