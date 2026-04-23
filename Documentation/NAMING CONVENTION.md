# Icon Naming Convention - RVTYY.ico

## Format

**RVTYY.ico** where:

- **RVT** = Prefix (constant)
- **YY** = Last 2 digits of Revit year
- **.ico** = Icon file format

## Examples

| Revit Version | Icon File | Year Mapping    |
| ------------- | --------- | --------------- |
| Revit 2014    | RVT14.ico | 2014 % 100 = 14 |
| Revit 2019    | RVT19.ico | 2019 % 100 = 19 |
| Revit 2023    | RVT23.ico | 2023 % 100 = 23 |
| Revit 2024    | RVT24.ico | 2024 % 100 = 24 |
| Revit 2025    | RVT25.ico | 2025 % 100 = 25 |
| Revit 2026    | RVT26.ico | 2026 % 100 = 26 |
| Revit 2027    | RVT27.ico | 2027 % 100 = 27 |
| Revit 2028    | RVT28.ico | 2028 % 100 = 28 |
| Revit 2030    | RVT30.ico | 2030 % 100 = 30 |

## Script Implementation

Scripts automatically convert:

```powershell
$Year = 2024
$YearShort = $Year % 100          # 24
$IconFile = "RVT$YearShort.ico"   # RVT24.ico
```

## Future-Proof

When new Revit versions are released:

1. Create icon
2. Name: RVTYY.ico
3. Upload to GitHub
4. Scripts automatically detect and deploy
5. **Zero script modifications needed**

## References

- https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
- https://www.bimpure.com/blog/revit-icons
