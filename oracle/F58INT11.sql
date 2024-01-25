
  -- CREATE UNIQUE INDEX "PRODDTA"."F58INT11_0" ON "PRODDTA"."F58INT11" ("SGUKID", "SGC75DCT")
  -- PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS COMPRESS ADVANCED LOW
  -- STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  -- PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  -- BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  -- TABLESPACE "PRODDTAI"


CREATE INDEX "PRODDTA"."F58INT11_2" ON "PRODDTA"."F58INT11" ("SGLRSSM", "SGDOCO")
PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS COMPRESS ADVANCED LOW
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
TABLESPACE "PRODDTAI"
PARALLEL 30;
ALTER INDEX "PRODDTA"."F58INT11_2" NOPARALLEL;


CREATE INDEX "PRODDTA"."F58INT11_3" ON "PRODDTA"."F58INT11" ("SG$TRANSID")
PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS COMPRESS ADVANCED LOW
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
TABLESPACE "PRODDTAI"
PARALLEL 30;
ALTER INDEX "PRODDTA"."F58INT11_3" NOPARALLEL;


CREATE INDEX "PRODDTA"."F58INT11_4" ON "PRODDTA"."F58INT11" ("SGC75DCT", "SGDOCO", "SGUKID" DESC)
PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS COMPRESS ADVANCED LOW
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
TABLESPACE "PRODDTAI"
PARALLEL 30;
ALTER INDEX "PRODDTA"."F58INT11_4" NOPARALLEL;


CREATE INDEX "PRODDTA"."F58INT11_6" ON "PRODDTA"."F58INT11" ("SG96RELID", "SGLRSSM")
PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS COMPRESS ADVANCED LOW
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
TABLESPACE "PRODDTAI"
PARALLEL 30;
ALTER INDEX "PRODDTA"."F58INT11_6" NOPARALLEL;


CREATE INDEX "PRODDTA"."F58INT11_7" ON "PRODDTA"."F58INT11" ("SG$RSP", "SGC75DCT")
PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS COMPRESS ADVANCED LOW
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
TABLESPACE "PRODDTAI"
PARALLEL 30;
ALTER INDEX "PRODDTA"."F58INT11_7" NOPARALLEL;

