"""Portable Markdown subset -> paginated PDF. Requires requirements-pdf.txt."""
import re
from functools import partial
import reportlab
from pathlib import Path
from xml.sax.saxutils import escape
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas
from pypdf import PdfReader


def main():
    root=Path(__file__).resolve().parent
    source=(root/'POSTMORTEM.md').read_text(encoding='utf-8')
    # Bitstream Vera is redistributable under the license bundled with ReportLab.
    # Resolve package assets, never an OS/user-specific font directory.
    fonts=Path(reportlab.__file__).resolve().parent/'fonts'
    for name,filename in [('Vera','Vera.ttf'),('Vera-Bold','VeraBd.ttf'),
                          ('Vera-Italic','VeraIt.ttf'),('Vera-BoldItalic','VeraBI.ttf')]:
        pdfmetrics.registerFont(TTFont(name,str(fonts/filename)))
    pdfmetrics.registerFontFamily('Vera',normal='Vera',bold='Vera-Bold',
                                  italic='Vera-Italic',boldItalic='Vera-BoldItalic')
    styles=getSampleStyleSheet()
    styles.add(ParagraphStyle(name='BodyExec',fontName='Vera',fontSize=10,leading=14,spaceAfter=8))
    styles['Title'].fontName='Vera-Bold'
    styles['Heading2'].fontName='Vera-Bold'
    styles['Title'].fontSize=20
    styles['Title'].leading=24
    styles['Title'].textColor=colors.HexColor('#17354A')
    styles['Heading2'].fontSize=12
    styles['Heading2'].leading=16
    styles['Heading2'].spaceBefore=9
    styles['Heading2'].spaceAfter=5
    story=[]
    for block in source.strip().split('\n\n'):
        if block.strip()=='<!-- pagebreak -->':
            story.append(PageBreak());continue
        for line in block.splitlines() if block.startswith('- ') else [block.replace('\n',' ')]:
            style='BodyExec'
            if line.startswith('# '):style='Title';line=line[2:]
            elif line.startswith('## '):style='Heading2';line=line[3:]
            line=escape(line)
            line=re.sub(r'\*\*(.*?)\*\*',r'<b>\1</b>',line)
            story.append(Paragraph(line,styles[style]))
    def footer(canvas,doc):
        canvas.saveState()
        canvas.setFont('Vera',8)
        canvas.setFillColor(colors.HexColor('#526270'))
        canvas.drawString(42,25,'PortalPagos | Post-mortem ejecutivo | Datos sintéticos')
        canvas.drawRightString(A4[0]-42,25,str(doc.page))
        canvas.restoreState()
    pdf=root/'POSTMORTEM.pdf'
    SimpleDocTemplate(str(pdf),pagesize=A4,rightMargin=42,leftMargin=42,topMargin=35,bottomMargin=42,
                      initialFontName='Vera',
                      title='PortalPagos - Post-mortem del 18 de septiembre de 2026',author='Equipo de análisis',
                      invariant=1).build(story,onFirstPage=footer,onLaterPages=footer,
                                         canvasmaker=partial(Canvas,initialFontName='Vera'))
    reader=PdfReader(pdf)
    if not 1<=len(reader.pages)<=3:raise ValueError('Post-mortem exceeds three pages')
    for page in reader.pages:
        if len(page.extract_text().strip())<100:raise ValueError('Empty or near-empty page')
        for resource in page['/Resources']['/Font'].values():
            font=resource.get_object()
            descriptor=font.get('/FontDescriptor')
            if not descriptor or '/FontFile2' not in descriptor.get_object():
                raise ValueError('All PDF fonts must be embedded TrueType')
    print(f'PDF generated: {len(reader.pages)} pages. Visual rendering review still required.')


if __name__=='__main__':main()
