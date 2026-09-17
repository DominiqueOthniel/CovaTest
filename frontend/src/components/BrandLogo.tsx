export default function BrandLogo({ className = '' }: { className?: string }) {
  return (
    <img
      src="/cova-logo.svg"
      alt="Cova"
      className={`brand-logo ${className}`.trim()}
    />
  )
}
