# Revit Icon Files

## Naming Convention

Icons use pattern: **RVTYY.ico** where YY = last 2 digits of Revit year

### Current Icons

- RVT23.ico = Revit 2023
- RVT24.ico = Revit 2024
- RVT25.ico = Revit 2025
- RVT26.ico = Revit 2026
- RVT27.ico = Revit 2027

### Adding New Versions

When Revit 2028 is released:

1. Create icon (256x256+)
2. Save as: RVT28.ico
3. Upload to this folder
4. Commit: "Add RVT28 icon"

Scripts automatically detect and deploy - no script changes needed!

## Icon Specifications

- Format: .ico (Windows icon format)
- Size: 256x256 minimum
- Multiple sizes: 256, 128, 96, 64, 48, 32, 24, 16
- Use distinct colors per version
- Include version number in design

## References

- https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
- https://www.bimpure.com/blog/revit-icons
