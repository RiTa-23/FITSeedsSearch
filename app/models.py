from typing import Optional
from sqlmodel import Field, SQLModel

class Seed(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    proposal_id: Optional[str] = Field(alias="研究課題/領域番号", index=True)
    project_title: Optional[str] = Field(alias="研究課題名", index=True)
    project_title_en: Optional[str] = Field(alias="研究課題名 (英文)")
    researcher_name: Optional[str] = Field(alias="教員名", index=True)
    representative: Optional[str] = Field(alias="研究代表者")
    keywords: Optional[str] = Field(alias="キーワード")
    research_field: Optional[str] = Field(alias="研究分野")
    description: Optional[str] = Field(alias="研究内容")
    description_en: Optional[str] = Field(alias="研究内容 (英文)")

    class Config:
        populate_by_name = True
