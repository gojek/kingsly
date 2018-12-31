module OpenSSLHelper
  def generate_root_ca(not_after)
    root_key = OpenSSL::PKey::RSA.new 2048
    root_ca = OpenSSL::X509::Certificate.new

    root_ca.not_before = Time.now
    root_ca.not_after = not_after

    root_ca.public_key = root_key.public_key
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = root_ca

    return root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)
  end
end
