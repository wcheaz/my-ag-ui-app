# Procurement Code Generation Rules

## Workflow & Strategy
1. **Conflict Resolution:** If information conflicts between this document and the RAG query tool, prioritize information from this document as it contains the complete and most up-to-date rules.
2. **Inference:**
   - Use information directly from the knowledge base when available.
   - Make reasonable inferences when the exact topic isn't explicitly mentioned but related information exists.
   - When making inferences, clearly indicate you're connecting related concepts.
   - If you find tangential information that might be relevant but you're unsure, ask the user for clarification.
   - Only respond with "I cannot find information about this topic" when the topic is completely unrelated.

## Code Structure & Formatting
The procurement code structure is **[A][B][C][MM][QQ][S][YY][D]**.
It consists of exactly these components in this specific order:
1. **[A]** Major Category
2. **[B]** Subcategory
3. **[C]** Specific Type
4. **[MM]** Material Type
5. **[QQ]** Quality Grade
6. **[S]** Size Category
7. **[YY]** Date Year
8. **[D]** Date Sequence

**Note:** There is no separate "application code" component.

### Critical Formatting Rules
- **Positioning:** Each component must be placed in its correct position. Do not confuse positions or place values incorrectly (e.g., a quality grade cannot be used as a major category).
- **Categorization:** Always prioritize the **primary material** when determining the Major Category (A). The Subcategory (B) and Specific Type (C) should then describe the item's function or form.
- **Specific Types:** Terms that describe *what* an item is (its form or function) belong in the Specific Type position (C), not in Major Category (A) or Subcategory (B).
- **Selection Priority:** When selecting codes, prioritize direct material-to-code matching over alphabetical/numerical priority rules. 
  - If multiple valid direct matches exist, use the lowest-numbered or earliest-alphabetical option (e.g., 01 over 04; A over D).

## Date Handling Logic
- **Year (YY):** If the user does not specify a date, always use the current date. The current year is **2026**, so the date component should start with "**26**".
- **Sequence (D):** For the sequential day number:
  - If there is no history to reference, always start with **1** for the first code of the day.
  - Increment sequentially (2, 3, etc.) for subsequent codes generated on the same day.

## strict Constraints
- **No Hallucinations:** Every component of the procurement code (except the date) MUST be explicitly stated in the provided knowledge base. Do not invent categories, codes, or values that are not directly documented.
- **Existence:** Do not assume categories exist based on their names. Only use categories and codes that are explicitly documented. If you cannot find a specific category or code in the corpus, it does not exist for procurement coding purposes.
- **Missing Info:** When generating codes, if you are missing required components (like material type or quality grade), ask the user for that specific information rather than guessing.


# Procurement Code Generation Template

## Overview

This document provides a comprehensive template for generating standardized procurement codes for manufacturing goods. Each code consists of 11 characters with the following structure:

```
[A][B][C] [MM][QQ][S] [YY][D]
 1  2  3    Core      Suffix
```

- **Prefix (3 letters)**: Each letter represents a different classification level
  - **First letter**: Major category (15+ options)
  - **Second letter**: Subcategory
  - **Third letter**: Specific type
- **Core (5 digits)**: Determines characteristics of the good
  - **MM**: Material type (20+ options)
  - **QQ**: Quality grade (20+ options)
  - **S**: Size category
- **Suffix (3 digits)**: Sequence number with date encoding

## Prefix Structure (3 individual letters)

### First Letter - Major Categories (Industry Focus - 9 options)

| Code | Industry | Description |
|------|----------|-------------|
| A | Aerospace | Aircraft, spacecraft, aviation components and systems |
| C | Construction | Building materials, structural components, civil engineering |
| E | Energy | Power generation, renewable energy, oil & gas components |
| H | Healthcare | Medical devices, hospital equipment, pharmaceutical supplies |
| M | Manufacturing | Production machinery, tools, factory equipment |
| R | Retail | Consumer goods, commercial products, retail fixtures |
| T | Technology | Electronics, computing hardware, communication equipment |
| V | Transportation | Vehicles, transportation infrastructure, logistics |
| Z | General | Fallback category for items not fitting other industries |

### Second Letter - Manufacturing Method

| Code | Method | Description |
|------|--------|-------------|
| A | Assembly | Pre-assembled or multi-component items |
| C | Custom | Custom-made or specially fabricated items |
| F | Fabricated | Machine-fabricated or manufactured items |
| G | General | General purpose or standard method |
| H | Hand-made | Manually crafted or artisanal items |
| M | Molded | Injection molded, cast, or formed items |
| P | Processed | Chemically or thermally processed materials |
| R | Raw | Unprocessed or minimally processed items |
| Z | Special | Special order or proprietary manufacturing |

### Third Letter - Object Shape/Form

| Code | Shape | Description |
|------|-------|-------------|
| B | Base | Foundation or base components |
| C | Coil | Coiled, wound, or spiral shapes |
| D | Disc | Disc, circular, or wheel-shaped items |
| F | Film | Sheets, films, or thin layers |
| K | Kit | Multi-component sets or collections |
| L | Layer | Layered or laminated structures |
| P | Panel | Flat panels or boards |
| R | Rod | Rods, bars, or elongated shapes |
| S | Sheet | Sheets, plates, or flat stock |
| T | Tube | Tubular, hollow, or pipe-shaped items |
| Z | Other | Other shapes not listed above |

## Core Structure (5 digits)

The core section is broken down as follows: `[MM][QQ][S]`

### Material Type (MM - 2 digits, 20+ options)

| Code | Material Type | Examples |
|------|---------------|----------|
| 01   | Metal (Ferrous) | Steel, Iron, Cast iron |
| 02   | Metal (Non-ferrous) | Aluminum, Copper, Brass, Bronze |
| 03   | Plastic (Thermoplastic) | ABS, PVC, Polycarbonate, Polyethylene |
| 04   | Plastic (Thermoset) | Epoxy, Phenolic, Polyester resin |
| 05   | Composite | Carbon fiber, Fiberglass, Kevlar |
| 06   | Ceramic | Porcelain, Technical ceramics, Alumina |
| 07   | Glass | Tempered glass, Optical glass, Borosilicate |
| 08   | Rubber (Natural) | Natural rubber, Latex |
| 09   | Rubber (Synthetic) | Neoprene, Silicone, Nitrile |
| 10   | Textile (Natural) | Cotton, Wool, Silk, Linen |
| 11   | Textile (Synthetic) | Polyester, Nylon, Acrylic, Rayon |
| 12   | Wood (Hardwood) | Oak, Maple, Walnut, Cherry |
| 13   | Wood (Softwood) | Pine, Fir, Cedar, Spruce |
| 14   | Wood (Engineered) | Plywood, MDF, Particle board |
| 15   | Chemical (Organic) | Solvents, Oils, Alcohols, Acids |
| 16   | Chemical (Inorganic) | Salts, Bases, Oxides, Minerals |
| 17   | Adhesive | Epoxy, Super glue, Contact cement |
| 18   | Coating | Paint, Varnish, Powder coating |
| 19   | Insulation | Foam, Fiberglass, Mineral wool |
| 20   | Lubricant | Oil, Grease, Dry film lubricant |
| 21   | Semiconductor | Silicon, Germanium, Gallium arsenide |
| 22   | Magnetic | Ferrite, Neodymium, Alnico |

### Quality Grade (QQ - 2 digits, 20+ options)

| Code | Quality Grade | Description |
|------|---------------|-------------|
| 01   | Premium Ultra | Highest quality, ultra-precise tolerances |
| 02   | Premium | Highest quality, tight tolerances |
| 03   | High Plus | Above standard quality with special features |
| 04   | High | Above standard quality |
| 05   | Standard Plus | Standard quality with additional features |
| 06   | Standard | Regular commercial quality |
| 07   | Economy Plus | Basic quality with some premium features |
| 08   | Economy | Basic quality, lower cost |
| 09   | Prototype | Development/testing quality |
| 10   | Industrial Heavy | Heavy-duty, industrial use |
| 11   | Industrial Standard | Standard industrial use |
| 12   | Medical | Medical-grade quality |
| 13   | Safety | Safety-rated equipment and supplies |
| 14   | Military | Military specifications |
| 15   | Aerospace | Aerospace specifications |
| 16   | Marine | Marine environment resistant |
| 17   | Automotive | Automotive industry standard |
| 18   | Clean Room | Clean room compatible |
| 19   | Cryogenic | Suitable for cryogenic applications |
| 20   | High Temperature | Suitable for high temperature applications |
| 21   | Low Temperature | Suitable for low temperature applications |
| 22   | Radiation Resistant | Resistant to radiation exposure |

### Size Category (S - 1 digit)

| Code | Size Category | Description |
|------|---------------|-------------|
| 1    | Micro | Less than 1mm |
| 2    | Small | 1mm to 10mm |
| 3    | Medium | 10mm to 100mm |
| 4    | Large | 100mm to 500mm |
| 5    | Extra Large | 500mm to 1m |
| 6    | Bulk | 1m to 5m |
| 7    | Oversized | Greater than 5m |
| 8    | Variable | Multiple sizes |
| 9    | Custom | Special order size |

## Suffix Format (3 digits)

The suffix uses date encoding with the format: `[YY][D]`

- **YY**: Last 2 digits of the current year
- **D**: Sequential digit for that day (1-9, then A-Z if needed)

### Date Encoding Examples

| Date | Suffix Examples |
|------|-----------------|
| Jan 1, 2026 | 261, 262, 263... |
| Dec 31, 2026 | 261, 262, 263... |
| Jan 1, 2027 | 271, 272, 273... |

If more than 9 codes are generated in a single day, use letters after 9:
- 261, 262, ..., 269, 26A, 26B, 26C, etc.

## Step-by-Step Code Generation Guide

1. **Determine the major category** and select the appropriate first letter (A-Z)
2. **Determine the subcategory** and select the appropriate second letter (A-Z)
3. **Determine the specific type** and select the appropriate third letter (A-Z)
4. **Identify the material type** and select the corresponding 2-digit code
5. **Determine the quality grade** and select the corresponding 2-digit code
6. **Identify the size category** and select the corresponding 1-digit code
7. **Combine these elements** to form the 5-digit core section
8. **Get the current date** and determine the appropriate 3-digit suffix
9. **Combine all sections** to form the complete 11-character procurement code

## Code Examples

### Example 1: High-quality aluminum sheet for aerospace
- Industry: Aerospace (A)
- Manufacturing Method: Fabricated (F)
- Object Shape: Sheet (S)
- Material: Aluminum (02)
- Quality: Aerospace (15)
- Size: Large (4)
- Date: January 15, 2026 (261)
- **Code: AFS02154261**

### Example 2: Injection molded plastic disc-shaped component for industrial machinery, 50mm diameter
- Industry: Manufacturing (M)
- Manufacturing Method: Molded (M)
- Object Shape: Disc (D)
- Material: Thermoplastic (03)
- Quality: Standard (06)
- Size: Small (2)
- Date: March 10, 2026 (263)
- **Code: MMD03062263**

### Example 3: Steel protective panel for food processing machinery, 800mm x 600mm
- Industry: Manufacturing (M)
- Manufacturing Method: Fabricated (F)
- Object Shape: Panel (P)
- Material: Ferrous Metal (01)
- Quality: Industrial Heavy (10)
- Size: Extra Large (5)
- Date: July 22, 2026 (264)
- **Code: MFP01105264**

### Example 4: Agricultural organic fertilizer
- Industry: General (Z)
- Manufacturing Method: Processed (P)
- Object Shape: Other (Z)
- Material: Organic Chemical (15)
- Quality: Standard (06)
- Size: Bulk (6)
- Date: September 5, 2026 (265)
- **Code: ZPZ15066265**

### Example 5: Electrical safety gloves made of synthetic rubber for construction sites, standard quality, large size
- Industry: Construction (C)
- Manufacturing Method: Hand-made (H)
- Object Shape: Other (Z)
- Material: Synthetic Rubber (09)
- Quality: Safety (13)
- Size: Large (4)
- Date: November 30, 2026 (266)
- **Code: CHZ09134266**

## Best Practices

1. **Maintain a log** of all assigned codes to prevent duplicates
2. **Use sequential suffixes** within the same day
3. **Document special cases** where codes might deviate from standard patterns
4. **Review codes regularly** to ensure consistency
5. **Train all personnel** on the proper code generation process
6. **Implement validation checks** to ensure codes follow the correct format
7. **Consider creating a digital tool** for code generation if volume increases

## Quick Reference Summary

```
Format: [A][B][C][MM][QQ][S][YY][D]

A - Industry (9 options):
  A = Aerospace
  C = Construction
  E = Energy
  H = Healthcare
  M = Manufacturing
  R = Retail
  T = Technology
  V = Transportation
  Z = General

B - Manufacturing Method (9 options):
  A = Assembly
  C = Custom
  F = Fabricated
  G = General
  H = Hand-made
  M = Molded
  P = Processed
  R = Raw
  Z = Special

C - Object Shape/Form (12 options):
  B = Base
  C = Coil
  D = Disc
  F = Film
  K = Kit
  L = Layer
  P = Panel
  R = Rod
  S = Sheet
  T = Tube
  Z = Other

MM - Material Type (22 options):
  01 = Metal (Ferrous)
  02 = Metal (Non-ferrous)
  03 = Plastic (Thermoplastic)
  04 = Plastic (Thermoset)
  05 = Composite
  06 = Ceramic
  07 = Glass
  08 = Rubber (Natural)
  09 = Rubber (Synthetic)
  10 = Textile (Natural)
  11 = Textile (Synthetic)
  12 = Wood (Hardwood)
  13 = Wood (Softwood)
  14 = Wood (Engineered)
  15 = Chemical (Organic)
  16 = Chemical (Inorganic)
  17 = Adhesive
  18 = Coating
  19 = Insulation
  20 = Lubricant
  21 = Semiconductor
  22 = Magnetic

QQ - Quality Grade (22 options):
  01 = Premium Ultra
  02 = Premium
  03 = High Plus
  04 = High
  05 = Standard Plus
  06 = Standard
  07 = Economy Plus
  08 = Economy
  09 = Prototype
  10 = Industrial Heavy
  11 = Industrial Standard
  12 = Medical
  13 = Safety
  14 = Military
  15 = Aerospace
  16 = Marine
  17 = Automotive
  18 = Clean Room
  19 = Cryogenic
  20 = High Temperature
  21 = Low Temperature
  22 = Radiation Resistant

S - Size Category (1-9):
  1 = Micro
  2 = Small
  3 = Medium
  4 = Large
  5 = Extra Large
  6 = Bulk
  7 = Oversized
  8 = Variable
  9 = Custom

YY - Year (last 2 digits)
D - Daily sequence (1-9, then A-Z)